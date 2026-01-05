import 'package:flutter/material.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';

class UserDetailsPopup extends StatelessWidget {
  final String userName;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback onClose;

  const UserDetailsPopup({
    super.key,
    required this.userName,
    required this.onEditProfile,
    required this.onSettings,
    required this.onLogout,
    required this.onClose,
  });

  static void show({
    required BuildContext context,
    required String userName,
    required VoidCallback onEditProfile,
    required VoidCallback onSettings,
    required VoidCallback onLogout,
  }) {
    showPopupCard(
      context: context,
      builder: (context) {
        return UserDetailsPopup(
          userName: userName,
          onEditProfile: onEditProfile,
          onSettings: onSettings,
          onLogout: onLogout,
          onClose: () => Navigator.of(context).pop(),
        );
      },
      offset: const Offset(-16, 70),
      alignment: Alignment.topRight,
      useSafeArea: true,
      dimBackground: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupCard(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with user info
            _buildUserHeader(),
            const SizedBox(height: 8),

            // Divider
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 8),

            // Menu items
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.edit,
          title: 'Edit Profile',
          onTap: onEditProfile,
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: onSettings,
        ),
        const SizedBox(height: 8),
        Divider(height: 1),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          onTap: onLogout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.black87,
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
}

// Enhanced PopupCard with arrow
class PopupCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;
  final ShapeBorder shape;

  const PopupCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.elevation = 8.0,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      elevation: elevation,
      shape: shape,
      child: child,
    );
  }
}

// Usage example in your app
class UserProfileManager extends StatelessWidget {
  final String currentUserName = "John Doe";

  const UserProfileManager({super.key});

  void _openUserPopup(BuildContext context) {
    UserDetailsPopup.show(
      context: context,
      userName: currentUserName,
      onEditProfile: () {
        Navigator.of(context).pop();
        _navigateToEditProfile();
      },
      onSettings: () {
        Navigator.of(context).pop();
        _navigateToSettings();
      },
      onLogout: () {
        Navigator.of(context).pop();
        _confirmLogout(context);
      },
    );
  }

  void _navigateToEditProfile() {
    // Navigate to edit profile screen
    print('Navigate to edit profile');
  }

  void _navigateToSettings() {
    // Navigate to settings screen
    print('Navigate to settings');
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // Perform logout logic
    print('User logged out');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _openUserPopup(context),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _openUserPopup(context),
          child: const Text('Open User Details'),
        ),
      ),
    );
  }
}

// Integration with your existing user header
class UserHeaderWithPopup extends StatelessWidget {
  final String userName;

  const UserHeaderWithPopup({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => UserDetailsPopup.show(
        context: context,
        userName: userName,
        onEditProfile: () {
          Navigator.of(context).pop();
          // Handle edit profile
        },
        onSettings: () {
          Navigator.of(context).pop();
          // Handle settings
        },
        onLogout: () {
          Navigator.of(context).pop();
          // Handle logout
        },
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User name on left
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userName,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // User icon on right
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
