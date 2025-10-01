class CourseModel {
  final String name;
  final String image;
  final double price;
  final String? referenceId;

  static const String collectionName = 'courses';

  CourseModel({
    required this.name,
    required this.image,
    required this.price,
    this.referenceId,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CourseModel(
      name: json['name'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
      referenceId: id,
    );
  }
  

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'price': price,
    };
  }
}

