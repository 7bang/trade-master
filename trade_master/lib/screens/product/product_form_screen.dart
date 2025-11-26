import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/product.dart';

/// 품목 등록/수정 화면
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId; // null이면 등록, 값이 있으면 수정

  const ProductFormScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _unitController = TextEditingController(text: '개');
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEdit = false;
  Product? _originalProduct;

  // 미리 정의된 카테고리 목록
  final List<String> _categories = [
    '과일',
    '채소',
    '수산물',
    '축산',
    '곡물',
    '가공식품',
    '기타',
  ];

  // 미리 정의된 단위 목록
  final List<String> _units = [
    '개',
    'kg',
    'g',
    '박스',
    '팩',
    '병',
    '봉',
    '마리',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    if (_isEdit) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ref.read(productProvider(widget.productId!).future);
      setState(() {
        _originalProduct = product;
        _nameController.text = product.name;
        _codeController.text = product.code ?? '';
        _categoryController.text = product.category ?? '';
        _unitPriceController.text =
            product.defaultUnitPrice?.toString() ?? '';
        _unitController.text = product.unit;
        _descriptionController.text = product.description ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('품목 정보 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _unitPriceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final business = await ref.read(currentBusinessProvider.future);

      if (business == null) {
        throw Exception('사업장 정보를 찾을 수 없습니다');
      }

      final unitPrice = _unitPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_unitPriceController.text.trim());

      if (_isEdit && _originalProduct != null) {
        // 수정
        final updatedProduct = _originalProduct!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          defaultUnitPrice: unitPrice,
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await service.updateProduct(updatedProduct);

        // Provider 갱신
        ref.invalidate(productsProvider);
        ref.invalidate(productProvider(widget.productId!));

        if (mounted) {
          context.go('/products');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('품목 정보가 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 등록
        final newProduct = Product(
          id: '', // Supabase에서 자동 생성
          businessId: business.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          defaultUnitPrice: unitPrice,
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.createProduct(newProduct);

        // Provider 갱신
        ref.invalidate(productsProvider);

        if (mounted) {
          context.go('/products');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('품목이 등록되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('품목 삭제'),
        content: const Text('이 품목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = ref.read(supabaseServiceProvider);
        await service.deleteProduct(widget.productId!);

        // Provider 갱신
        ref.invalidate(productsProvider);

        if (mounted) {
          context.go('/products');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('품목이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '품목 수정' : '품목 등록'),
        actions: _isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '삭제',
                  onPressed: _deleteProduct,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 아이콘
                Icon(
                  _isEdit ? Icons.edit : Icons.add_box,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? '품목 정보를 수정하세요' : '새 품목을 등록하세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),

                // 품목명 (필수)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '품목명',
                    hintText: '예: 한라봉',
                    prefixIcon: Icon(Icons.inventory_2),
                    helperText: '필수 입력',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '품목명을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 품목 코드 (선택)
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: '품목 코드',
                    hintText: '예: FRUIT-001',
                    prefixIcon: Icon(Icons.qr_code),
                    helperText: '선택 입력 (고유 코드)',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // 카테고리 (선택)
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _categories;
                    }
                    return _categories.where((category) {
                      return category
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (value) {
                    _categoryController.text = value;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    if (_categoryController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _categoryController.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: '카테고리',
                        hintText: '예: 과일',
                        prefixIcon: Icon(Icons.category),
                        helperText: '선택 입력',
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        _categoryController.text = value;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 기본 단가 및 단위 (가로 배치)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _unitPriceController,
                        decoration: const InputDecoration(
                          labelText: '기본 단가',
                          hintText: '예: 8000',
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: '선택 입력',
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _units;
                          }
                          return _units.where((unit) {
                            return unit
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (value) {
                          _unitController.text = value;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (_unitController.text.isNotEmpty && controller.text.isEmpty) {
                            controller.text = _unitController.text;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: '단위',
                              hintText: '예: kg',
                              helperText: '단위',
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              _unitController.text = value;
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '단위 입력';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 설명 (선택)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '설명',
                    hintText: '품목에 대한 설명을 입력하세요',
                    prefixIcon: Icon(Icons.description),
                    helperText: '선택 입력',
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveProduct(),
                ),
                const SizedBox(height: 32),

                // 저장 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? '수정 완료' : '등록하기',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // 취소 버튼
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text(
                      '취소',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
