# Online multiplayer Caro design

## Purpose and scope

Add a two-player online Caro mode backed solely by Supabase. The existing
offline game remains unchanged. Authenticated users choose an offline or online
mode after signing in. The online mode provides a small lobby, immediate games
between two available players, synchronized play, persisted moves and results,
rematches, and forfeits. Chat, new audio, and non-essential animation are out
of scope.

The initial release must operate within Supabase's Free tier for a small beta:
no Edge Functions, cron jobs, or other platforms; no lobby-wide polling or
lobby-wide move broadcasts.

## Product decisions

- Choosing an available player starts a game immediately; there is no invitation
  acceptance step.
- A player may participate in at most one active game.
- A player who explicitly leaves an active game forfeits it.
- A disconnected player forfeits after 60 seconds without a game-session
  heartbeat, when the remaining client claims the timeout.
- When a game ends, either player may create the next game immediately with the
  same opponent. Leaving returns the player to the online lobby.
- Every online game uses the current 20 by 20 board and five-in-a-row rules.

## Architecture

Flutter remains a client-only app. Supabase Postgres is the authoritative game
state and historical store; Postgres functions exposed as Supabase RPCs make
all state-changing decisions. Flutter does not decide whether a move is legal
or whether a game has finished.

Supabase Realtime has two narrowly scoped roles:

1. A single Presence channel represents users currently in the online lobby.
   Presence metadata holds the user's id, display name, and client-side lobby
   status. It is ephemeral, so entering/leaving the lobby does not create
   database rows or recurring database writes.
2. Each active game subscribes only to its own game and moves. The two
   participants receive new moves and result changes; players in the lobby do
   not receive them.

The lobby treats a player as `playing` when Presence says so or when the
player's client has received an active game. Presence is a UX signal only:
`create_online_game` is authoritative and refuses an opponent or caller that
already has an active game. This safely handles a short delay or a stale
Presence update.

## Database model

### `games`

One row per online game.

| Field | Meaning |
| --- | --- |
| `id` | UUID primary key. |
| `player_x_id`, `player_o_id` | References to the two authenticated players. |
| `status` | `active`, `completed`, or `forfeited`. |
| `current_mark` | The mark allowed to move next while active. |
| `winner_id` | Winner, or null for a draw. |
| `result` | `x_win`, `o_win`, `draw`, `x_forfeit`, or `o_forfeit`. |
| `move_count` | Number of persisted moves. |
| `created_at`, `finished_at` | Audit and future leaderboard data. |

Constraints prevent a player from appearing twice in one game and restrict
status, mark, and result values. Partial indexes on both player columns for
active games support the availability check. Only participants may select a
game through RLS; direct client insert/update/delete permissions are not
granted.

### `game_moves`

An append-only replay record. Each row stores `game_id`, zero-based or
one-based move number (chosen consistently in the migration), player id, mark,
row, column, and timestamp. A primary/unique constraint on `(game_id,
move_number)` preserves ordering, and one on `(game_id, row, column)` prevents
duplicate occupancy. Participants may select moves for their games; no direct
write access is granted.

### `game_sessions`

Small transient table keyed by `(game_id, player_id)`, containing only
`last_seen`. It is updated by an active player's heartbeat every 30 seconds,
never added to the Realtime publication, and removed when a game finishes.
It permits a server-side timeout decision without trusting a client assertion
that the opponent disconnected.

## RPC contract

All RPCs require `auth.uid()` and raise a clear domain error for invalid state.
Each mutating RPC uses a database transaction and locks the relevant game row;
game creation additionally takes deterministic locks for both user ids to
prevent concurrent invitations creating two games.

### `create_online_game(opponent_id)`

Rejects self-invitation and any caller/opponent with an active game, selects X
and O, creates the game plus two session rows, and returns the game id and
initial state.

### `play_online_move(game_id, row, column)`

Validates that the game is active, the caller owns `current_mark`, coordinates
are on the 20 by 20 board, and the cell is empty. It appends the move, counts
consecutive marks around that move in all four directions, and atomically
updates the next turn or final result. A full board is a draw.

### `touch_game_session(game_id)`

Updates only the caller's session timestamp while they are an active game
participant. The Flutter game screen calls it immediately on entry and every
30 seconds while active.

### `forfeit_online_game(game_id)`

Ends an active game with the caller's mark as the forfeiting mark and the
opponent as winner; it removes both session rows.

### `claim_opponent_timeout(game_id)`

Ends an active game only when the caller is a participant and the opponent's
session heartbeat is older than 60 seconds. It awards the caller the win and
removes both session rows. The game screen checks periodically while the game
is active.

### `start_rematch(game_id)`

Uses the same availability locking as game creation to create a fresh game for
the two prior participants. It is allowed only after the original game is
finished and neither player has entered another active game.

## Flutter components and flow

### Mode selection

`AuthGate` opens a new mode-selection screen after authentication. Selecting
Offline navigates to the existing `CaroGameScreen` without changing its rules
or controls. Selecting Online opens `OnlineLobbyScreen`.

### Online lobby

The lobby joins and tracks the Presence channel on entry and untracks/leaves
on disposal. It renders current users with profile display names. Available
players have a single Mời button; players known to be active appear Đang chơi
and cannot be selected. A successful invitation navigates the caller to
`OnlineGameScreen`; the invited player receives their new game through their
participant-scoped game subscription and is navigated there automatically.

### Online game

`OnlineGameScreen` reuses extracted board rendering and win-line presentation
from the offline screen so visual behaviour is the same. It derives the board,
current player, move count, and winning line from the game/move stream. It
disables all cells except empty cells on the local player's turn. Tapping one
sends an RPC rather than mutating the local board optimistically.

The screen starts a 30-second session heartbeat and a lightweight timeout
check while a game is active. It offers a leave action that invokes the
forfeit RPC before returning to the lobby.

### End-of-game dialog

For an online result, a non-dismissible dialog offers only Chơi ván tiếp theo
and Rời đi. The first calls `start_rematch`; the second returns to the lobby.
It does not add the offline-only board-view action. The stored completed board
remains available for future replay work.

## Realtime, errors, and lifecycle

- Subscriptions are created once per relevant screen and removed in `dispose`.
- A reconnect re-fetches the game and moves before accepting another move.
- A failed invitation, stale move, or timeout claim shows a concise Vietnamese
  SnackBar and reloads authoritative state; no speculative local board is kept.
- If a player backgrounds or closes the app long enough to stop heartbeats,
  they can lose by timeout. This is an explicit simplification of the initial
  product.
- Logout first leaves Presence and forfeits any active online game, then signs
  the user out.

## Security

RLS limits reads of games, moves, and sessions to their participants. Client
roles receive select permissions only where needed and no direct mutation
permissions for game state. RPCs use the authenticated caller identity and
explicit participant/turn checks. The migration grants only the required RPC
execute permissions to `authenticated` and revokes public access.

## Free-tier budget strategy

- Lobby membership uses Presence; it does not periodically update a database
  row and broadcast that update to everyone.
- Moves are normalized individual rows, so each Realtime event carries one
  move instead of an ever-growing board JSON document.
- At most the two game participants subscribe to each move. A 100-move game
  therefore delivers roughly 200 move messages before small presence/result
  overhead, rather than delivering moves to every lobby member.
- Heartbeats are database RPC writes to a table outside Realtime publication;
  they consume no Realtime messages.
- The feature is intentionally limited to the Free tier's 200 concurrent
  Realtime connections and 2 million monthly Realtime messages. Retaining
  every game will eventually consume the Free tier's 500 MB database limit;
  monitoring usage and a later archive/retention policy are required before
  larger-scale launch, but deletion or external archival is not part of this
  feature.

## Testing and verification

1. Unit tests cover pure board reconstruction and game-result helpers shared
   by online UI, including horizontal, vertical, and both diagonal wins.
2. Widget tests cover mode choice, lobby state rendering, disabled opponent
   turns, terminal dialog choices, and user-facing error states using injected
   repository fakes.
3. Migration verification through Supabase CLI checks schema, RLS, RPC grants,
   and required indexes against the linked project.
4. Two authenticated test users manually verify invitation, simultaneous
   invitation rejection, move synchronization, draw/win persistence,
   rematch, explicit forfeit, and heartbeat timeout.
5. `flutter analyze` and `flutter test` must pass before handoff.

## Non-goals

- Chat, spectator mode, matchmaking, notifications, rankings, replay UI, game
  history UI, reconnection grace beyond the 60-second timeout, and visual/audio
  enhancements are deliberately excluded.
