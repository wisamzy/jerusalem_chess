import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chess_1/providers/authentication_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../authentication/login_screen.dart';
import '../helper/helper_methods.dart';
import '../providers/theme_language_provider.dart';
import '../service/assests_manager.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool rememberLoginDetails = false;
  String profileImage = 'assets/profile_picture.png'; // Initial profile image path
  late ThemeLanguageProvider _themeLanguageProvider;
  Map<String, dynamic> translations = {};
  File? finalFileImage;

  void selectImage({required bool fromCamera}) async {
    try {
      finalFileImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (e) {
          if (mounted) {
            showSnackBar(context: context, content: e.toString());
          }
        },
      );

      if (finalFileImage != null) {
        cropImage(finalFileImage!.path);
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error selecting image: $e');
    }
  }

  void cropImage(String path) async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        maxHeight: 800,
        maxWidth: 800,
      );

      if (croppedFile != null) {
        finalFileImage = File(croppedFile.path);
        setState(() {
          profileImage =
              finalFileImage!.path; // Update profile image optimistically
        });

        // Update user image
        authProvider.updateUserImage(
          uid: authProvider.userModel!.uid, // Replace with actual user ID
          fileImage: finalFileImage!,
          onSuccess: () {
            if (mounted) {
              authProvider.showSnackBar(context: context,
                  content: 'Profile image updated successfully.',color: Colors.green);
            }
          },
          onFail: (error) {
            if (mounted) {
              showSnackBar(context: context,
                  content: 'Failed to update profile image: $error');
            }
          },
        );
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error cropping image: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeLanguageProvider = Provider.of<ThemeLanguageProvider>(context);
    loadTranslations(_themeLanguageProvider.currentLanguage).then((value) {
      if (mounted) {
        setState(() {
          translations = value;
        });
      }
    });
  }

  void reloadTranslations(String language) {
    loadTranslations(language).then((value) {
      if (mounted) {
        setState(() {
          translations = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _themeLanguageProvider.isLightMode ? Colors.black : Colors
        .white;
    final backgroundColor =
    _themeLanguageProvider.isLightMode ? Colors.white : const Color(0xFF121212);
    final userModel = context
        .watch<AuthenticationProvider>()
        .userModel;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xff4e3c96),
        title: Text(getTranslation('settings', translations),style: const TextStyle(color: Colors.white, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
        actions: [
          // Dark mode toggle button
          IconButton(
            icon: Icon(
                _themeLanguageProvider.isLightMode ? Icons.light_mode : Icons
                    .dark_mode),
            color: _themeLanguageProvider.isLightMode ? const Color(0xfff0c230) : const Color(0xfff0f5f7),
            onPressed: _themeLanguageProvider.toggleThemeMode,
          ),
          // Language change button
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String selectedLanguage) {
              _themeLanguageProvider.changeLanguage(selectedLanguage);
              reloadTranslations(selectedLanguage);
            },
            itemBuilder: (BuildContext context) =>
            [
              const PopupMenuItem<String>(
                value: 'Arabic',
                child: Text('العربية'),
              ),
              const PopupMenuItem<String>(
                value: 'English',
                child: Text('English'),
              ),
            ],
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showProfileImageDialog(userModel?.image ?? '');
                  },
                  child: Stack(
                    children: [
                      ClipOval(
                        child: Image.network(
                          userModel?.image ?? AssetsManager.userIcon,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(AssetsManager.userIcon), // Fallback image
                            );
                          },
                        ),

                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            showOptionsDialog();
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt , color: textColor,),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userModel!.name,
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(getTranslation('DarkMode', translations),style:  TextStyle(color: textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            value: !_themeLanguageProvider.isLightMode,
            onChanged: (bool value) {
              _themeLanguageProvider.toggleThemeMode();
            },
          ),
          SwitchListTile(
            title: Text(getTranslation('Remember Login Details', translations),style:  TextStyle(color:textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            value: rememberLoginDetails,
            onChanged: (bool value) {
              setState(() {
                rememberLoginDetails = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(getTranslation('helpSupport', translations),style:  TextStyle(color:textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            onTap: () {
              // Add help/support functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(getTranslation('signOut', translations),style:  TextStyle(color:textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            onTap: () {
              context.read<AuthenticationProvider>()
                  .sighOutUser()
                  .whenComplete(() {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(getTranslation('notifications', translations),style:  TextStyle(color:textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            onTap: () {
              // Add notifications settings functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(getTranslation('privacySecurity', translations),style:  TextStyle(color:textColor, fontFamily: 'IBM Plex Sans Arabic', fontWeight: FontWeight.w700),),
            onTap: () {
              // Add privacy and security settings functionality
            },
          ),
        ],
      ),
    );
  }

  void showProfileImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  selectImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  selectImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text('Delete Current Photo'),
                onTap: () async {
                  Navigator.pop(context);

                  try {
                    final authProvider = context.read<AuthenticationProvider>();
                    final defaultImage = AssetsManager.userIcon;

                    // Update local state optimistically
                    setState(() {
                      profileImage = defaultImage;
                      finalFileImage = null;
                    });

                    // Update Firestore
                    authProvider.updateUserImage(
                      uid: authProvider.userModel!.uid,
                      fileImage: null, // Pass null to indicate deletion
                      onSuccess: () {
                        if (mounted) {
                          // Update userModel.image directly
                          authProvider.userModel!.image = defaultImage;

                          // Show Snackbar
                          showSnackBar(
                            context: context,
                            content: 'Profile image updated successfully.',
                          );
                        }
                      },
                      onFail: (error) {
                        if (mounted) {
                          showSnackBar(
                            context: context,
                            content: 'Failed to update profile image: $error',
                          );
                        }
                      },
                    );


                  } catch (e) {
                    print('Error deleting image: $e');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



}
