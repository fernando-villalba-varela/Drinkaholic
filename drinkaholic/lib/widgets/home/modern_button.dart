import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModernButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final Gradient gradient;
  final bool isSmaller;

  const ModernButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.icon,
    required this.gradient,
    this.isSmaller = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: isSmaller ? 50.h : 60.h,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isSmaller ? 25.r : 30.r),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(
                (0.3 * 255).round(),
                gradient.colors.first.red,
                gradient.colors.first.green,
                gradient.colors.first.blue,
              ),
              blurRadius: 18.r,
              spreadRadius: 1.5.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isSmaller ? 25.r : 30.r),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: isSmaller ? 20.sp : 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmaller ? 15.sp : 17.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
