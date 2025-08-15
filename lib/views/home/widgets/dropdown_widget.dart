import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ListOption { item, business, event }

class DropdownListWidget extends StatefulWidget {
  final VoidCallback? onItemTap;
  final VoidCallback? onBusinessTap;
  final VoidCallback? onEventTap;
  final ListOption selectedOption;
  final Color backgroundColor;
  final Color textColor;
  final Color selectedColor;
  final double borderRadius;

  const DropdownListWidget({
    Key? key,
    this.onItemTap,
    this.onBusinessTap,
    this.onEventTap,
    this.selectedOption = ListOption.item,
    this.backgroundColor = const Color(0xFFFF9500),
    this.textColor = Colors.white,
    this.selectedColor = Colors.white,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  State<DropdownListWidget> createState() => _DropdownListWidgetState();
}

class _DropdownListWidgetState extends State<DropdownListWidget>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  ListOption currentSelection = ListOption.item;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    currentSelection = widget.selectedOption;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void toggleDropdown() {
    if (isExpanded) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() {
      isExpanded = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _closeDropdown() {
    setState(() {
      isExpanded = false;
    });

    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void selectOption(ListOption option, VoidCallback? callback) {
    setState(() {
      currentSelection = option;
    });
    _closeDropdown();
    if (callback != null) {
      callback();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: 200,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 2),
              child: Material(
                elevation: 4.0,
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _expandAnimation.value,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: _expandAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // List An Item
                              _buildDropdownItem(
                                "List An Item",
                                ListOption.item,
                                widget.onItemTap,
                              ),

                              // Divider
                              Container(
                                height: 0.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                color: Colors.white.withOpacity(0.3),
                              ),

                              // List A Business
                              _buildDropdownItem(
                                "List A Business",
                                ListOption.business,
                                widget.onBusinessTap,
                              ),

                              // Divider
                              Container(
                                height: 0.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                color: Colors.white.withOpacity(0.3),
                              ),

                              // List An Event
                              _buildDropdownItem(
                                "List An Event",
                                ListOption.event,
                                widget.onEventTap,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  String getSelectedText() {
    switch (currentSelection) {
      case ListOption.item:
        return "List An Item";
      case ListOption.business:
        return "List A Business";
      case ListOption.event:
        return "List An Event";
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/List.png', width: 20.w, height: 20.h),
              const SizedBox(width: 6),
              Text(
                "List",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(
    String text,
    ListOption option,
    VoidCallback? onTap,
  ) {
    bool isSelected = currentSelection == option;

    return GestureDetector(
      onTap: () => selectOption(option, onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Appthemes.textSmall.copyWith(
                  color: widget.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? widget.selectedColor : appColors.white,
                  width: 1,
                ),
                // color: isSelected ? widget.selectedColor : Colors.transparent,
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 11.w,
                          height: 11.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                appColors.darkBlue, // White dot in the center
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
