import 'dart:typed_data';
import 'package:firebase_chat_example/constants.dart';
import 'package:flutter/material.dart';

import 'package:google_place/google_place.dart';

import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailScreen({
    Key? key,
    required this.placeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GooglePlace googlePlace = GooglePlace(googleMapsApiKey);
    DetailsResult? detailsResult;
    List<Uint8List> images = [];
    List<String> photoReferances = [];

    Future<void> getDetails(String placeId) async {
      var response = await googlePlace.details.get(placeId);
      if (response != null && response.result != null) {
        detailsResult = response.result;
        if (detailsResult?.photos?.isNotEmpty ?? false) {
          detailsResult?.photos?.forEach(
            (element) {
              if (element.photoReference?.isNotEmpty ?? false) {
                photoReferances.add(element.photoReference.toString());
              }
            },
          );
          // photoReferances.forEach((element) {});
          var result = await googlePlace.photos.get(photoReferances.first, 200, 400);
          if (result != null) {
            images.add(result);
          }
        }
      }
    }

    return FutureBuilder(
      future: getDetails(placeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: SimplerCustomLoader(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Details"),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              getDetails(placeId);
            },
            child: const Icon(Icons.refresh),
          ),
          body: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 250,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.memory(
                                images[index],
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListView(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 15, top: 10),
                            child: const Text(
                              "Details",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (detailsResult != null && detailsResult?.types != null)
                            Container(
                              margin: const EdgeInsets.only(left: 15, top: 10),
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: detailsResult?.types?.length ?? 0,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Chip(
                                      label: Text(
                                        detailsResult?.types?[index] ?? 'Empty',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(left: 15, top: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.location_on),
                              ),
                              title: Text('Address: ${detailsResult?.formattedAddress ?? 'Empty'}'),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 15, top: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.location_searching),
                              ),
                              title: Text(
                                'Geometry: ${detailsResult?.geometry?.location?.lat ?? 'Empty'}, ${detailsResult?.geometry?.location?.lng ?? 'Empty'}',
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 15, top: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.timelapse),
                              ),
                              title: Text('UTC offset: ${detailsResult?.utcOffset.toString()} min'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
