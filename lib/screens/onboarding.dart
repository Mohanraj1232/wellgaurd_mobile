import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/models/contact_model.dart';
import 'package:wellguard_ai/models/onboarding_request.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:dio/dio.dart';

class OnboardingScreen extends StatefulWidget {
  final int userId;

  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<Contact> _contacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  bool _isLoading = false;

  bool _isValidPhoneNumber(String phone) {
    // Basic phone number validation (10-15 digits with optional + and -)
    final regex = RegExp(r'^[+]?[0-9]{10,10}$');
    return phone.isEmpty || regex.hasMatch(phone.replaceAll('-', ''));
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Add Contact',
          style: TextStyle(color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Contact Name',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.bgHover,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.bgHover,
                  errorText: _phoneController.text.isNotEmpty &&
                          !_isValidPhoneNumber(_phoneController.text)
                      ? 'Invalid phone number'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'WhatsApp Number',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.bgHover,
                  errorText: _whatsappController.text.isNotEmpty &&
                          !_isValidPhoneNumber(_whatsappController.text)
                      ? 'Invalid WhatsApp number'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter contact name')),
                );
                return;
              }
              if (_phoneController.text.isEmpty &&
                  _whatsappController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Please enter phone number or WhatsApp number')),
                );
                return;
              }
              if (_phoneController.text.isNotEmpty &&
                  !_isValidPhoneNumber(_phoneController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid phone number')),
                );
                return;
              }
              if (_whatsappController.text.isNotEmpty &&
                  !_isValidPhoneNumber(_whatsappController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid WhatsApp number')),
                );
                return;
              }

              setState(() {
                _contacts.add(
                  Contact(
                    name: _nameController.text,
                    phoneNumber: _phoneController.text,
                    whatsappNumber: _whatsappController.text,
                  ),
                );
              });
              _nameController.clear();
              _phoneController.clear();
              _whatsappController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Add',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare contacts data
      final List<ContactData> contactsData = _contacts
          .map((contact) => ContactData(
                name: contact.name,
                phoneNumber: contact.phoneNumber,
                whatsappNumber: contact.whatsappNumber,
              ))
          .toList();

      final apiClient = DioClient.getApiClient();
      final response = await apiClient.saveContacts(
        OnboardingRequest(
          userId: widget.userId,
          contacts: contactsData,
        ),
      );

      if (response.success) {
        final prefs = await SharedPreferences.getInstance();

        // Save login status and user id
        await prefs.setBool('isloggedin', true);
        await prefs.setInt('userid', widget.userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Contacts saved successfully'),
            ),
          );

          // Navigate to home screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        }
      } else {
        // Success is false
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Error saving contacts')),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Error saving contacts';
        
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check if the backend server is running.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please ensure backend is running.';
        } else if (e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contacts: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add emergency contacts that will be notified in case of emergency',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contacts_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts added yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Card(
                        color: AppColors.bgCard,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (contact.phoneNumber.isNotEmpty)
                                Text(
                                  'Phone: ${contact.phoneNumber}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              if (contact.whatsappNumber != null && contact.whatsappNumber!.isNotEmpty)
                                Text(
                                  'WhatsApp: ${contact.whatsappNumber}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: AppColors.accentDanger,
                            onPressed: () => _removeContact(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.textWhite),
                        SizedBox(width: 8),
                        Text(
                          'Add Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveContacts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textWhite,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
