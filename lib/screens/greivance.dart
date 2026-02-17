import 'package:flutter/material.dart';
import 'package:wellguard_ai/theme/colors.dart';

class GrievancePage extends StatelessWidget {
  const GrievancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'GrievX',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          // leading: Builder(
          //   builder: (context) => IconButton(
          //     icon: const Icon(Icons.menu, color: AppColors.textWhite),
          //     onPressed: () => Scaffold.of(context).openDrawer(),
          //   ),
          // ),
        ),
      body: const Center(
        child: Text(
          'Grievance Page',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
