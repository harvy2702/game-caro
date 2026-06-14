import 'dart:math';

enum BotDifficulty { easy, hard }

class CaroBot {
  final int boardSize;
  final String botSymbol = 'O';
  final String playerSymbol = 'X';
  final Random _random = Random();

  CaroBot(this.boardSize);

  /// Tìm nước đi tốt nhất cho Bot
  List<int>? findBestMove(List<List<String>> board, BotDifficulty difficulty) {
    List<Map<String, dynamic>> moves = [];

    // Kiểm tra xem bàn cờ có trống hoàn toàn không (nước đi đầu tiên)
    bool isEmpty = true;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != "") {
          isEmpty = false;
          break;
        }
      }
      if (!isEmpty) break;
    }

    if (isEmpty) {
      // Đánh vào giữa bàn cờ
      return [boardSize ~/ 2, boardSize ~/ 2];
    }

    // Duyệt qua tất cả các ô trống để tính điểm
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == "") {
          int attackScore = _evaluateCell(board, r, c, botSymbol);
          int defenseScore = _evaluateCell(board, r, c, playerSymbol);
          
          // Điểm tổng: Ưu tiên tấn công một chút (nếu điểm ngang nhau)
          int totalScore = attackScore + defenseScore;
          
          // Đặc biệt: Nếu có thể thắng ngay (tấn công), ưu tiên tuyệt đối
          if (attackScore >= 1000000) {
            totalScore += 2000000;
          } else if (defenseScore >= 1000000) {
            // Nếu người chơi sắp thắng, phải chặn ngay
            totalScore += 1000000;
          }

          if (totalScore > 0) {
            moves.add({
              'row': r,
              'col': c,
              'score': totalScore,
            });
          }
        }
      }
    }

    if (moves.isEmpty) {
      // Nếu không có ô nào có điểm (hiếm khi xảy ra), chọn ngẫu nhiên ô trống
      return _getRandomEmptyCell(board);
    }

    // Sắp xếp các nước đi theo điểm giảm dần
    moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    if (difficulty == BotDifficulty.hard) {
      // Chọn ra danh sách các nước đi có điểm bằng với điểm cao nhất
      int maxScore = moves.first['score'] as int;
      List<Map<String, dynamic>> bestMoves = moves.where((m) => m['score'] == maxScore).toList();
      // Chọn ngẫu nhiên 1 trong các nước đi tốt nhất (để bot đa dạng hơn)
      var chosen = bestMoves[_random.nextInt(bestMoves.length)];
      return [chosen['row'] as int, chosen['col'] as int];
    } else {
      // Mức dễ: Lấy top 5 nước đi, chọn ngẫu nhiên.
      // Điều này khiến bot thỉnh thoảng không chặn những nước chí mạng hoặc bỏ lỡ cơ hội thắng.
      int topN = min(5, moves.length);
      var chosen = moves[_random.nextInt(topN)];
      return [chosen['row'] as int, chosen['col'] as int];
    }
  }

  int _evaluateCell(List<List<String>> board, int row, int col, String player) {
    int totalScore = 0;
    
    // 4 hướng: Ngang, Dọc, Chéo xuôi, Chéo ngược
    final directions = [
      [0, 1],   // Ngang
      [1, 0],   // Dọc
      [1, 1],   // Chéo xuôi
      [-1, 1],  // Chéo ngược
    ];

    for (var dir in directions) {
      int dr = dir[0];
      int dc = dir[1];
      
      int consecutiveCount = 1;
      int blockedEnds = 0;

      // Chiều tiến
      int i = 1;
      while (true) {
        int nr = row + i * dr;
        int nc = col + i * dc;
        if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
          if (board[nr][nc] == player) {
            consecutiveCount++;
            i++;
          } else if (board[nr][nc] != "") {
            // Chặn bởi đối thủ
            blockedEnds++;
            break;
          } else {
            // Trống
            break;
          }
        } else {
          // Chặn bởi biên bàn cờ
          blockedEnds++;
          break;
        }
      }

      // Chiều lùi
      i = 1;
      while (true) {
        int nr = row - i * dr;
        int nc = col - i * dc;
        if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
          if (board[nr][nc] == player) {
            consecutiveCount++;
            i++;
          } else if (board[nr][nc] != "") {
            blockedEnds++;
            break;
          } else {
            break;
          }
        } else {
          blockedEnds++;
          break;
        }
      }

      totalScore += _getPatternScore(consecutiveCount, blockedEnds);
    }

    return totalScore;
  }

  int _getPatternScore(int count, int blocked) {
    if (count >= 5) return 1000000;
    
    if (count == 4) {
      if (blocked == 0) return 100000; // Open 4 (Chắc chắn thắng)
      if (blocked == 1) return 10000;  // Closed 4 (Có thể thắng nếu tới lượt)
      return 0; // Blocked cả 2 đầu
    }
    
    if (count == 3) {
      if (blocked == 0) return 10000;  // Open 3
      if (blocked == 1) return 1000;   // Closed 3
      return 0;
    }
    
    if (count == 2) {
      if (blocked == 0) return 1000;   // Open 2
      if (blocked == 1) return 100;    // Closed 2
      return 0;
    }

    if (count == 1) {
      if (blocked == 0) return 10;
      if (blocked == 1) return 1;
      return 0;
    }

    return 0;
  }

  List<int>? _getRandomEmptyCell(List<List<String>> board) {
    List<List<int>> emptyCells = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == "") {
          emptyCells.add([r, c]);
        }
      }
    }
    if (emptyCells.isEmpty) return null;
    return emptyCells[_random.nextInt(emptyCells.length)];
  }
}
