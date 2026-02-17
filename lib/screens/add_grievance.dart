import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/models/grievance_model.dart';

class AddGrievanceScreen extends StatefulWidget {
  const AddGrievanceScreen({super.key});

  @override
  State<AddGrievanceScreen> createState() => _AddGrievanceScreenState();
}

class _AddGrievanceScreenState extends State<AddGrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  List<DepartmentDropdown> _departments = [];
  DepartmentDropdown? _selectedDepartment;
  File? _selectedImage;
  bool _isLoadingDepartments = true;
  bool _isSubmitting = false;
  String? _error;

  // ML Analysis state
  bool _isAnalysing = false;
  bool _analysisComplete = false;
  String? _analysisError;

  // Audio recording state
  String? _audioPath;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.getDepartmentsDropdown();

      if (response.success && response.data != null) {
        setState(() {
          _departments = response.data!;
          _isLoadingDepartments = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load departments';
          _isLoadingDepartments = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = _getErrorMessage(e);
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingDepartments = false;
      });
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server.';
    } else if (e.response != null) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'];
      }
    }
    return 'An error occurred. Please try again.';
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo',
                  style: TextStyle(color: AppColors.textMain)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: AppColors.textMain)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppColors.accentDanger),
                title: const Text('Remove Image',
                    style: TextStyle(color: AppColors.accentDanger)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisComplete = false;
          _analysisError = null;
          // Clear previously auto-filled fields
          _titleController.clear();
          _descriptionController.clear();
          _selectedDepartment = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _analyseImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() {
      _isAnalysing = true;
      _analysisError = null;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: _selectedImage!.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await dio.post(
        'https://foster-postcentral-al.ngrok-free.dev/predict',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;

      if (data['success'] == true) {
        // Auto-fill form fields
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';

        // Match department from ML category to existing dropdown values
        final mlCategory = (data['category'] ?? '').toString().toLowerCase();
        DepartmentDropdown? matchedDept;
        for (final dept in _departments) {
          if (dept.name.toLowerCase().contains(mlCategory) ||
              mlCategory.contains(dept.name.toLowerCase())) {
            matchedDept = dept;
            break;
          }
        }

        setState(() {
          _selectedDepartment = matchedDept;
          _analysisComplete = true;
          _isAnalysing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image analysed successfully! Fields auto-filled.'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      } else {
        // Road is clean or no damage found
        setState(() {
          _isAnalysing = false;
          _analysisError = data['description'] ?? 'No issue detected in the image.';
          _selectedImage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['description'] ?? 'No issue detected. Please upload a different photo.'),
              backgroundColor: AppColors.accentDanger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } on DioException catch (e) {
      setState(() {
        _isAnalysing = false;
        _analysisError = _getErrorMessage(e);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${_getErrorMessage(e)}')),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalysing = false;
        _analysisError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  // ============= AUDIO RECORDING FUNCTIONS =============

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      // Check and request permission
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory for storing the recording
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/grievance_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        // Start timer to track duration
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration++;
            });
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied. Please enable it in settings.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      
      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording() async {
    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
    }
    
    setState(() {
      _audioPath = null;
      _recordingDuration = 0;
    });
  }

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.addGrievance(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        departmentId: _selectedDepartment!.id,
        imagePath: _selectedImage?.path,
        audioPath: _audioPath,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grievance submitted successfully!'),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message ?? 'Failed to submit grievance')),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submit Grievance',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingDepartments
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && _departments.isEmpty
              ? _buildErrorState()
              : _buildForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.accentDanger,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoadingDepartments = true;
                });
                _loadDepartments();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment_add,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Grievance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fill in the details to submit your grievance',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Upload & Analyse Section
            const Text(
              'Upload Road Image',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isAnalysing ? null : _pickImage,
              child: Container(
                height: _selectedImage != null ? 200 : 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _analysisError != null
                        ? AppColors.accentDanger
                        : _analysisComplete
                            ? AppColors.secondary
                            : AppColors.borderLight,
                    width: _analysisComplete || _analysisError != null ? 2 : 1,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (!_isAnalysing)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _analysisComplete = false;
                                    _analysisError = null;
                                    _titleController.clear();
                                    _descriptionController.clear();
                                    _selectedDepartment = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentDanger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppColors.textWhite,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (_isAnalysing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: AppColors.textWhite),
                                    SizedBox(height: 12),
                                    Text(
                                      'Analysing image...',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _analysisError != null
                                ? 'Upload a different image'
                                : 'Tap to upload road image',
                            style: TextStyle(
                              color: _analysisError != null
                                  ? AppColors.accentDanger
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_analysisError != null && _selectedImage == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _analysisError!,
                  style: const TextStyle(
                    color: AppColors.accentDanger,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Analyse Button
            if (_selectedImage != null && !_analysisComplete)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isAnalysing
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: _isAnalysing ? AppColors.bgCard : null,
                    borderRadius: BorderRadius.circular(12),
                    border: _isAnalysing
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                    boxShadow: _isAnalysing
                        ? null
                        : const [
                            BoxShadow(
                              color: AppColors.shadowPrimary,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isAnalysing ? null : _analyseImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAnalysing) ...[
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Analysing...',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.auto_fix_high,
                              color: AppColors.textWhite,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Analyse Image',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_analysisComplete)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentSuccess, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.accentSuccess,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Analysis Complete',
                      style: TextStyle(
                        color: AppColors.accentSuccess,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Department Dropdown
            const Text(
              'Department',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              key: ValueKey(_selectedDepartment?.id ?? 'no-dept'),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonFormField<DepartmentDropdown>(
                value: _selectedDepartment,
                hint: const Text(
                  'Select Department',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppColors.textMain, fontSize: 16),
                items: _departments.map((dept) {
                  return DropdownMenuItem<DepartmentDropdown>(
                    value: dept,
                    child: Text(dept.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Title Field
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Enter grievance title',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description Field
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textMain),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your grievance in detail...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Audio Recording Section
            const Text(
              'Voice Recording (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Recording status / Audio preview
                  if (_isRecording) ...[
                    // Recording indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.accentDanger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recording... ${_formatDuration(_recordingDuration)}',
                          style: const TextStyle(
                            color: AppColors.accentDanger,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stop button
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentDanger,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ] else if (_audioPath != null) ...[
                    // Audio recorded preview
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.audiotrack,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Audio Recorded',
                                style: TextStyle(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Duration: ${_formatDuration(_recordingDuration)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete button
                        IconButton(
                          onPressed: _deleteRecording,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.accentDanger,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Start recording button
                    Column(
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to record audio',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic),
                          label: const Text('Start Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGrievance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.textWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Grievance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
