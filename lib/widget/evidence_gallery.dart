import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../service/request_service.dart';
import '../service/response_service.dart';

class EvidenceGallery extends StatelessWidget {
  final String title;
  final List<ItemEvidence> evidence;

  const EvidenceGallery({
    Key? key,
    required this.title,
    required this.evidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (evidence.isEmpty) return const SizedBox();

    String baseUrlNor = RequestServ.isDebug? "http://172.16.2.147:8000" : "https://instaladores.geovoy.com/api";

    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Esto hace que solo ocupe el espacio necesario
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          /// 🔥 Indicador de arrastre (Handle)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// 🔥 Header elegante
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 18,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.blueGrey.withOpacity(0.1),
                ),
                child: Text(
                  "${evidence.length}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 18),

          /// 🔥 Gallery
          Flexible( // Usamos Flexible por si hay muchas fotos, que permita scroll interno
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: evidence.map((item) {
                  final imageUrl = "$baseUrlNor${item.imageUrl}";

                  return GestureDetector(
                    onTap: () => _openPreview(context, imageUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              width: 105,
                              height: 105,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.45),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}