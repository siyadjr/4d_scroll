import 'package:flutter/material.dart';

class Node {
  String name;
  Map<String, Node> childrens;

  Node({required this.name, this.childrens = const {}});
}

class TreeViewApp extends StatelessWidget {
  const TreeViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alternating Tree Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TreeViewScreen(),
    );
  }
}

class TreeViewScreen extends StatelessWidget {
  const TreeViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample deeply nested data
    List<Node> rootNodes = [
      Node(
        name: 'Parent 1',
        childrens: {
          'child1': Node(
            name: 'Child 1',
            childrens: {
              'grandchild1': Node(
                name: 'Grandchild 1',
                childrens: {
                  'greatGrandchild1': Node(name: 'Great Grandchild 1'),
                  'greatGrandchild2': Node(name: 'Great Grandchild 2'),
                },
              ),
              'grandchild2': Node(name: 'Grandchild 2'),
            },
          ),
          'child2': Node(name: 'Child 2'),
        },
      ),
      Node(
        name: 'Parent 2',
        childrens: {
          'child3': Node(
            name: 'Child 3',
            childrens: {'grandchild3': Node(name: 'Grandchild 3')},
          ),
        },
      ),
      Node(name: 'Parent 3'),
    ];

    return Scaffold(body: AlternatingSwipeView(nodes: rootNodes));
  }
}

class AlternatingSwipeView extends StatefulWidget {
  final List<Node> nodes;

  const AlternatingSwipeView({super.key, required this.nodes});

  @override
  State<AlternatingSwipeView> createState() => _AlternatingSwipeViewState();
}

class _AlternatingSwipeViewState extends State<AlternatingSwipeView> {
  @override
  Widget build(BuildContext context) {
    // Start with vertical scrolling for root nodes (depth 0)
    return SafeArea(
      child: NodeGridView(nodes: widget.nodes, depth: 0, parentPath: const []),
    );
  }
}

class NodeGridView extends StatefulWidget {
  final List<Node> nodes;
  final int depth;
  final List<String> parentPath;

  const NodeGridView({
    super.key,
    required this.nodes,
    required this.depth,
    required this.parentPath,
  });

  @override
  State<NodeGridView> createState() => _NodeGridViewState();
}

class _NodeGridViewState extends State<NodeGridView> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _showingChildren = false;
  List<Node>? _currentChildren;
  late List<String> _currentPath;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    _currentPath = List.from(widget.parentPath);
    if (widget.nodes.isNotEmpty) {
      _currentPath.add(widget.nodes[0].name);
    }
  }

  void _onPageChanged() {
    if (_pageController.hasClients) {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentPageIndex && newIndex < widget.nodes.length) {
        setState(() {
          _currentPageIndex = newIndex;
          _showingChildren = false;
          if (_currentPath.isNotEmpty) {
            _currentPath.removeLast();
          }
          _currentPath.add(widget.nodes[_currentPageIndex].name);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  Axis get _scrollDirection =>
      widget.depth % 2 == 0 ? Axis.vertical : Axis.horizontal;

  Color _getBackgroundColor() {
    List<Color> colors = [
      Colors.blue.shade50,
      Colors.amber.shade50,
      Colors.teal.shade50,
      Colors.pink.shade50,
      Colors.purple.shade50,
      Colors.indigo.shade50,
    ];
    return colors[widget.depth % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_showingChildren &&
        _currentChildren != null &&
        _currentChildren!.isNotEmpty) {
      return NodeGridView(
        nodes: _currentChildren!,
        depth: widget.depth + 1,
        parentPath: _currentPath,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_showingChildren) {
          setState(() {
            _showingChildren = false;
          });
          return false;
        }
        return true;
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: _scrollDirection,
            itemCount: widget.nodes.length,
            itemBuilder: (context, index) {
              final node = widget.nodes[index];
              final hasChildren = node.childrens.isNotEmpty;

              return GestureDetector(
                onTap: hasChildren
                    ? () {
                        setState(() {
                          _currentChildren = node.childrens.values.toList();
                          _showingChildren = true;
                        });
                      }
                    : null,
                child: Container(
                  color: _getBackgroundColor(),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                node.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              if (hasChildren) ...[
                                Text(
                                  '${node.childrens.length} ${node.childrens.length == 1 ? 'Child' : 'Children'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade500,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.depth % 2 == 0
                                            ? Icons.arrow_forward
                                            : Icons.arrow_downward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tap to View Children',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Leaf Node (No Children)',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _buildNavigationIndicators(index, node),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Level ${widget.depth + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_tree,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _currentPath.join(' > '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.depth > 0)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _scrollDirection == Axis.vertical
                        ? Icons.swap_vert
                        : Icons.swap_horiz,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _scrollDirection == Axis.vertical
                        ? 'Scroll Vertically'
                        : 'Scroll Horizontally',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.nodes.length > 1)
            Positioned(
              bottom: widget.depth % 2 == 0 ? 16 : null,
              right: widget.depth % 2 == 0 ? null : 16,
              left: widget.depth % 2 == 0 ? 0 : null,
              top: widget.depth % 2 == 0 ? null : 0,
              child: Container(
                width: widget.depth % 2 == 0 ? double.infinity : 30,
                height: widget.depth % 2 == 0 ? 30 : double.infinity,
                alignment: Alignment.center,
                child: _scrollDirection == Axis.vertical
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.nodes.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentPageIndex
                                  ? Colors.blue.shade500
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.nodes.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentPageIndex
                                  ? Colors.blue.shade500
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationIndicators(int index, Node node) {
    final hasNext = index < widget.nodes.length - 1;
    final hasPrevious = index > 0;
    final hasChildren = node.childrens.isNotEmpty;

    return Stack(
      children: [
        if (hasNext && _scrollDirection == Axis.horizontal)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.black.withOpacity(0.3),
                size: 36,
              ),
            ),
          ),
        if (hasPrevious && _scrollDirection == Axis.horizontal)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.black.withOpacity(0.3),
                size: 36,
              ),
            ),
          ),
        if (hasNext && _scrollDirection == Axis.vertical)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black.withOpacity(0.3),
                size: 36,
              ),
            ),
          ),
        if (hasPrevious && _scrollDirection == Axis.vertical)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.black.withOpacity(0.3),
                size: 36,
              ),
            ),
          ),
        if (hasChildren)
          Positioned(
            bottom: widget.depth % 2 == 0 ? 60 : 16,
            right: widget.depth % 2 == 0 ? 16 : 60,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.depth % 2 == 0
                    ? Icons.arrow_forward
                    : Icons.arrow_downward,
                color: Colors.blue.shade800,
              ),
            ),
          ),
      ],
    );
  }
}