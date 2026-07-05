// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';

class CaroGameScreen extends StatefulWidget {
  const CaroGameScreen({super.key});

  @override
  State<CaroGameScreen> createState() => _CaroGameScreenState();
}

class _CaroGameScreenState extends State<CaroGameScreen> {
  // --- Cấu hình game (Game Configuration) ---
  int _boardSize = 20; // Kích thước bàn cờ mặc định: 20x20
  final double _cellSize = 44.0; // Kích thước của mỗi ô cờ (pixel)
  double _sidebarWidth = 320.0; // Chiều rộng mặc định của sidebar

  // --- Trạng thái game (Game State) ---
  late List<List<String>> _board; // Bàn cờ 2D chứa các giá trị: "", "X", "O"
  String _currentPlayer = "X"; // Người chơi hiện tại ("X" hoặc "O")
  String? _winner; // Lưu người chiến thắng ("X", "O", "Draw" hoặc null nếu chưa kết thúc)
  List<List<int>> _winningLine = []; // Danh sách tọa độ [row, col] của 5 ô chiến thắng để highlight
  int _moveCount = 0; // Đếm số nước đi để phát hiện hòa cờ nhanh hơn

  // --- Điểm số (Scoreboard) ---
  int _xWins = 0;
  int _oWins = 0;
  int _draws = 0;

  // --- Trạng thái tương tác chuột & Lịch sử nước đi (Hover & Move State) ---
  int? _hoveredRow;
  int? _hoveredCol;

  String get _playerXName {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['username'] as String? ?? 'Player X';
  }

  String? get _playerXEmail {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email;
  }

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Khởi tạo bàn cờ trống
  void _initializeBoard() {
    _board = List.generate(_boardSize, (_) => List.generate(_boardSize, (_) => ""));
    _currentPlayer = "X";
    _winner = null;
    _winningLine = [];
    _moveCount = 0;
    _hoveredRow = null;
    _hoveredCol = null;
  }



  // Đặt lại trò chơi (giữ nguyên điểm số)
  void _resetGame() {
    setState(() {
      _initializeBoard();
    });
  }

  // Đặt lại điểm số về 0
  void _resetScores() {
    setState(() {
      _xWins = 0;
      _oWins = 0;
      _draws = 0;
      _initializeBoard();
    });
  }

  // Thay đổi kích thước bàn cờ
  void _changeBoardSize(int newSize) {
    setState(() {
      _boardSize = newSize;
      _initializeBoard();
    });
  }

  // --- Thuật toán kiểm tra thắng thua (Win Checking Algorithm) ---
  // Thuật toán này sẽ kiểm tra xem nước đi vừa rồi tại ô (row, col) có tạo thành
  // một hàng 5 ô liên tiếp cùng màu theo 4 hướng (Ngang, Dọc, Chéo xuôi, Chéo ngược) hay không.
  bool _checkWin(int r, int c, String player) {
    // Định nghĩa 4 hướng kiểm tra: [deltaRow, deltaCol]
    final directions = [
      [0, 1],   // Ngang (Trái sang Phải)
      [1, 0],   // Dọc (Trên xuống Dưới)
      [1, 1],   // Chéo xuôi (\)
      [-1, 1],  // Chéo ngược (/)
    ];

    for (var dir in directions) {
      int dr = dir[0];
      int dc = dir[1];
      List<List<int>> tempLine = [[r, c]]; // Lưu tọa độ của các ô liên tiếp cùng ký tự

      // 1. Đi theo chiều dương (tiến về phía trước)
      int i = 1;
      while (true) {
        int nr = r + i * dr;
        int nc = c + i * dc;
        // Kiểm tra xem ô tiếp theo có hợp lệ và cùng ký tự của người chơi không
        if (nr >= 0 && nr < _boardSize && nc >= 0 && nc < _boardSize && _board[nr][nc] == player) {
          tempLine.add([nr, nc]);
          i++;
        } else {
          break;
        }
      }

      // 2. Đi theo chiều âm (lùi về phía sau)
      i = 1;
      while (true) {
        int nr = r - i * dr;
        int nc = c - i * dc;
        if (nr >= 0 && nr < _boardSize && nc >= 0 && nc < _boardSize && _board[nr][nc] == player) {
          tempLine.add([nr, nc]);
          i++;
        } else {
          break;
        }
      }

      // Nếu tìm thấy từ 5 ô liên tiếp trở lên
      if (tempLine.length >= 5) {
        _winningLine = tempLine; // Ghi nhận đường thắng để tô màu highlight trên giao diện
        return true;
      }
    }
    return false;
  }

  // --- Xử lý sự kiện khi bấm vào ô cờ ---
  void _makeMove(int row, int col) {
    // Nếu ô đã được đánh hoặc game đã kết thúc thì không làm gì cả
    if (_board[row][col] != "" || _winner != null) return;

    setState(() {
      _board[row][col] = _currentPlayer;
      _moveCount++;

      // Kiểm tra xem nước đi này có thắng không
      if (_checkWin(row, col, _currentPlayer)) {
        _winner = _currentPlayer;
        if (_currentPlayer == "X") {
          _xWins++;
        } else {
          _oWins++;
        }
        
        _showGameOverDialog("$_currentPlayer Chiến Thắng!");
      }
      // Kiểm tra hòa cờ nếu đã đánh hết bàn cờ
      else if (_moveCount == _boardSize * _boardSize) {
        _winner = "Draw";
        _draws++;
        _showGameOverDialog("Hòa cờ!");
      }
      // Đổi lượt đi cho người chơi tiếp theo
      else {
        _currentPlayer = _currentPlayer == "X" ? "O" : "X";
      }
    });
  }

  // --- Hiển thị thông báo khi game kết thúc ---
  void _showGameOverDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
          ),
          title: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: title.contains("X")
                    ? const Color(0xFF00E5FF)
                    : title.contains("O")
                        ? const Color(0xFFFF4081)
                        : Colors.white,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Trò chơi đã kết thúc. Bạn có muốn chơi ván mới không?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nút đóng hộp thoại để xem lại bàn cờ vừa đánh
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text("Xem bàn cờ"),
                  ),
                  const SizedBox(width: 12),
                  // Nút chơi lại ngay lập tức
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Chơi ván mới"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Kiểm tra xem ô (row, col) có nằm trong đường thắng không ---
  bool _isWinningCell(int row, int col) {
    for (var cell in _winningLine) {
      if (cell[0] == row && cell[1] == col) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12), // Màu nền tối sang trọng
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161C),
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text(
              "Caro Premium",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white70),
            tooltip: 'Hồ sơ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
                  ),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              // Layout dành cho màn hình lớn (PC/Tablet ngang): Sidebar bên trái, Bàn cờ bên phải
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar (Trái)
                  Container(
                    width: _sidebarWidth,
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        _buildScoreBoard(),
                        const Spacer(),
                        _buildControlBar(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Thanh kéo điều chỉnh độ rộng Sidebar
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (details) {
                        setState(() {
                          _sidebarWidth += details.delta.dx;
                          // Giới hạn độ rộng sidebar từ 250px đến 500px
                          if (_sidebarWidth < 250) _sidebarWidth = 250;
                          if (_sidebarWidth > 600) _sidebarWidth = 600;
                        });
                      },
                      child: Container(
                        width: 16,
                        color: Colors.transparent, // Vùng bắt chạm rộng để dễ kéo
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bàn cờ (Phải)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 16.0),
                      child: _buildGameBoardContainer(),
                    ),
                  ),
                ],
              );
            } else {
              // Layout dành cho màn hình nhỏ (Mobile): Cột dọc truyền thống
              return Column(
                children: [
                  const SizedBox(height: 12),
                  // 1. Khu vực hiển thị Điểm số & Trạng thái lượt đi
                  _buildScoreBoard(),
                  const SizedBox(height: 16),

                  // 2. Bàn cờ Caro (Zoomable & Pannable)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: _buildGameBoardContainer(),
                    ),
                  ),

                  // 3. Thanh công cụ bên dưới (Menu & Khởi động lại)
                  _buildControlBar(),
                  const SizedBox(height: 16),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // --- Widget: Bảng hiển thị điểm số và lượt đi ---
  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: const Color(0xFF1A1A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C35), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Hàng điểm số
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPlayerScoreCard(
                      _playerXName,
                      _xWins,
                      const Color(0xFF00E5FF),
                      _currentPlayer == "X" && _winner == null,
                      email: _playerXEmail,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _buildDrawScoreCard(),
                  ),
                  Expanded(
                    child: _buildPlayerScoreCard(
                      "Player O",
                      _oWins,
                      const Color(0xFFFF4081),
                      _currentPlayer == "O" && _winner == null,
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2C2C35), height: 24),
              // Trạng thái hiện tại
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                children: [
                  const Text(
                    "Trạng thái:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (_winner != null) ...[
                    Text(
                      _winner == "Draw" ? "Hòa cờ!" : "$_winner chiến thắng! 🎉",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _winner == "X"
                            ? const Color(0xFF00E5FF)
                            : _winner == "O"
                                ? const Color(0xFFFF4081)
                                : Colors.amber,
                      ),
                    ),
                  ] else ...[
                    const Text("Lượt của", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentPlayer == "X"
                            ? const Color(0xFF00E5FF).withOpacity(0.15)
                            : const Color(0xFFFF4081).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentPlayer,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentPlayer == "X"
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFFFF4081),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thẻ hiển thị điểm số của từng người chơi
  Widget _buildPlayerScoreCard(String name, int score, Color color, bool isActive, {String? email}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.white70,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 2),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white38,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ hiển thị số trận hòa
  Widget _buildDrawScoreCard() {
    return Column(
      children: [
        const Text(
          "Hòa",
          style: TextStyle(fontSize: 13, color: Colors.white30),
        ),
        const SizedBox(height: 6),
        Text(
          _draws.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  // --- Widget: Vùng chứa bàn cờ có chức năng Zoom và Pan ---
  Widget _buildGameBoardContainer() {
    final double boardTotalWidth = _boardSize * _cellSize;

    return Center(
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF131317),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C35), width: 1.5),
        ),
        elevation: 6,
        child: Column(
          children: [
            // Hướng dẫn nhỏ cho người chơi
            Container(
              width: double.infinity,
              color: const Color(0xFF1A1A22),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.zoom_in, size: 16, color: Colors.white54),
                  SizedBox(width: 6),
                  Text(
                    "Cuộn chuột/Hai ngón tay để Thu Phóng & Di Chuyển bàn cờ",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Vùng InteractiveViewer cho phép cuộn và thu phóng bàn cờ mượt mà
            Expanded(
              child: InteractiveViewer(
                minScale: 0.4,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(100),
                child: Center(
                  child: Container(
                    width: boardTotalWidth,
                    height: boardTotalWidth,
                    decoration: const BoxDecoration(
                      color: Color(0xFF131317),
                    ),
                    child: Stack(
                      children: [
                        // Vẽ bàn cờ 2D bằng GridView
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _boardSize,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _boardSize * _boardSize,
                          itemBuilder: (context, index) {
                            int row = index ~/ _boardSize;
                            int col = index % _boardSize;
                            return _buildCell(row, col);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Vẽ một ô cờ đơn lẻ ---
  Widget _buildCell(int row, int col) {
    final String val = _board[row][col];
    final bool isWinning = _isWinningCell(row, col);
    final bool isHovered = _hoveredRow == row && _hoveredCol == col;

    // Màu viền và màu nền ô cờ
    Color cellBgColor = const Color(0xFF131317);
    if (isWinning) {
      cellBgColor = const Color(0xFFFFD700).withOpacity(0.25); // Màu vàng óng khi thắng cuộc
    } else if (isHovered && val == "" && _winner == null) {
      cellBgColor = Colors.white.withOpacity(0.03); // Đổi nhẹ nền khi di chuột qua ô trống
    }

    Widget cellWidget = Container(
      decoration: BoxDecoration(
        color: cellBgColor,
        border: Border.all(
          color: isWinning
              ? const Color(0xFFFFD700)
              : const Color(0xFF2C2C35), // Màu viền lưới
          width: isWinning ? 2.0 : 0.8,
        ),
      ),
      child: Center(
        child: _buildCellSymbol(row, col, val, isWinning, isHovered),
      ),
    );

    return MouseRegion(
      cursor: (val == "" && _winner == null) ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() {
          _hoveredRow = row;
          _hoveredCol = col;
        });
      },
      onExit: (_) {
        setState(() {
          if (_hoveredRow == row && _hoveredCol == col) {
            _hoveredRow = null;
            _hoveredCol = null;
          }
        });
      },
      child: GestureDetector(
        onTap: () => _makeMove(row, col),
        child: cellWidget,
      ),
    );
  }

  // Vẽ biểu tượng X, O bên trong ô cờ
  Widget _buildCellSymbol(int row, int col, String val, bool isWinning, bool isHovered) {
    // 1. Trường hợp ô đã được đánh
    if (val != "") {
      final Color symbolColor = val == "X" ? const Color(0xFF00E5FF) : const Color(0xFFFF4081);
      
      Widget textWidget = Text(
        val,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: symbolColor,
          shadows: [
            BoxShadow(
              color: symbolColor.withOpacity(0.6),
              blurRadius: isWinning ? 12 : 4,
            ),
          ],
        ),
      );

      return textWidget;
    }

    // 2. Trường hợp ô trống nhưng chuột đang di qua (Xem trước nước đi - Preview)
    if (isHovered && _winner == null) {
      final String previewChar = _currentPlayer;
      final Color previewColor = previewChar == "X"
          ? const Color(0xFF00E5FF).withOpacity(0.3)
          : const Color(0xFFFF4081).withOpacity(0.3);

      return Text(
        previewChar,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: previewColor,
        ),
      );
    }

    // 3. Ô trống bình thường
    return const SizedBox.shrink();
  }

  // --- Widget: Thanh công cụ bên dưới điều chỉnh Game ---
  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chọn kích thước bàn cờ
              Row(
                children: [
                  const Text(
                    "Kích thước: ",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2C2C35)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _boardSize,
                        dropdownColor: const Color(0xFF1A1A22),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            _changeBoardSize(newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 20, child: Text("20 x 20")),
                          DropdownMenuItem(value: 25, child: Text("25 x 25")),
                          DropdownMenuItem(value: 30, child: Text("30 x 30")),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Nút xóa điểm số
              TextButton.icon(
                onPressed: _resetScores,
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white60),
                label: const Text(
                  "Đặt lại điểm",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nút Chơi ván mới
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.replay),
              label: const Text(
                "Chơi ván mới",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
