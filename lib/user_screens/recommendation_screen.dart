import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Recommendations')),
        resizeToAvoidBottomInset: false,
        body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              mainAxisExtent: 230),
          padding: const EdgeInsets.all(8.0),
          itemCount: 8,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {},
              child: Card(
                elevation: 10,
                borderOnForeground: true,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    children: [
                     CachedNetworkImage(
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.fill,
                        imageUrl:
                            "https://images.pexels.com/photos/11850741/pexels-photo-11850741.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load",
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            new Icon(Icons.error),
                      ),
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: const [
                              Flexible(
                                child: Text(
                                  'Book help to earn money',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                "\$50",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
