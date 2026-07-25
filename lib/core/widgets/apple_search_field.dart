import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppleSearchField extends StatelessWidget {
  const AppleSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;

        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.searchFill(context),
            borderRadius: AppRadii.search,
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(
                CupertinoIcons.search,
                size: 18,
                color: AppColors.secondaryLabel(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryLabel(context),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (hasText)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onClear?.call();
                    onChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 18,
                      color: AppColors.secondaryLabel(context),
                    ),
                  ),
                )
              else
                const SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }
}
