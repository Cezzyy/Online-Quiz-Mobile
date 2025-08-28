import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = DummyData.getUser();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            const SizedBox(height: 40),
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.profileImageUrl.isNotEmpty
                  ? (user.profileImageUrl.startsWith('assets/')
                      ? AssetImage(user.profileImageUrl) as ImageProvider
                      : NetworkImage(user.profileImageUrl))
                  : null,
              child: user.profileImageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            
            // User Name
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Student ID
            Text(
              user.studentId,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            
            // Email
             Text(
               user.email,
               style: TextStyle(
                 fontSize: 14,
                 color: Colors.grey[600],
               ),
             ),
             const SizedBox(height: 32),
             
             // User Details Card
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.grey.withValues(alpha: 0.1),
                     spreadRadius: 1,
                     blurRadius: 10,
                     offset: const Offset(0, 2),
                   ),
                 ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     'Profile Details',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: Colors.black87,
                     ),
                   ),
                   const SizedBox(height: 16),
                   _buildDetailRow(Icons.school_outlined, 'Degree', user.degree),
                   const SizedBox(height: 12),
                   _buildDetailRow(Icons.phone_outlined, 'Phone', user.phoneNumber),
                   const SizedBox(height: 12),
                   _buildDetailRow(Icons.contact_emergency_outlined, 'Emergency Contact', user.emergencyContact),
                   if (user.bio.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     _buildDetailRow(Icons.info_outline, 'Bio', user.bio),
                   ],
                 ],
               ),
             ),
             const SizedBox(height: 32),
             
             // Action Buttons
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const EditProfileScreen(),
                         ),
                       );
                     },
                     icon: const Icon(Icons.edit_outlined),
                     label: const Text('Edit Profile'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue.shade600,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const SettingsScreen(),
                         ),
                       );
                     },
                     icon: const Icon(Icons.settings_outlined),
                     label: const Text('Settings'),
                     style: OutlinedButton.styleFrom(
                       foregroundColor: Colors.blue.shade600,
                       side: BorderSide(color: Colors.blue.shade600),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}