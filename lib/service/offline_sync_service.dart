import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:instaladores_new/service/request_service.dart';

class OfflineSyncJob {
  final int? id;
  final String ticketId;
  final String type; 
  final String status; 
  final String observations;
  final String technicianName;
  final String unitId;
  final String timestamp;
  final String changedBy;
  final String phase; 
  
  int statusSynced; 
  int formSynced;   
  String photosJson; 

  OfflineSyncJob({
    this.id,
    required this.ticketId,
    required this.type,
    this.status = 'pending',
    required this.observations,
    required this.technicianName,
    required this.unitId,
    required this.timestamp,
    required this.changedBy,
    required this.phase,
    this.statusSynced = 0,
    this.formSynced = 0,
    required this.photosJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'type': type,
      'status': status,
      'observations': observations,
      'technicianName': technicianName,
      'unitId': unitId,
      'timestamp': timestamp,
      'changedBy': changedBy,
      'phase': phase,
      'statusSynced': statusSynced,
      'formSynced': formSynced,
      'photosJson': photosJson,
    };
  }

  factory OfflineSyncJob.fromMap(Map<String, dynamic> map) {
    return OfflineSyncJob(
      id: map['id'],
      ticketId: map['ticketId'],
      type: map['type'],
      status: map['status'],
      observations: map['observations'],
      technicianName: map['technicianName'],
      unitId: map['unitId'],
      timestamp: map['timestamp'],
      changedBy: map['changedBy'],
      phase: map['phase'],
      statusSynced: map['statusSynced'],
      formSynced: map['formSynced'],
      photosJson: map['photosJson'],
    );
  }
}

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._init();
  static Database? _database;

  OfflineSyncService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_sync.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        observations TEXT,
        technicianName TEXT,
        unitId TEXT,
        timestamp TEXT,
        changedBy TEXT,
        phase TEXT,
        statusSynced INTEGER DEFAULT 0,
        formSynced INTEGER DEFAULT 0,
        photosJson TEXT
      )
    ''');
  }

  Future<int> saveJob(OfflineSyncJob job) async {
    final db = await instance.database;
    return await db.insert('offline_jobs', job.toMap());
  }

  Future<List<OfflineSyncJob>> getPendingJobs() async {
    final db = await instance.database;
    final result = await db.query('offline_jobs');
    return result.map((json) => OfflineSyncJob.fromMap(json)).toList();
  }

  Future<void> updateJob(OfflineSyncJob job) async {
    final db = await instance.database;
    await db.update('offline_jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  Future<void> deleteJob(int id) async {
    final db = await instance.database;
    await db.delete('offline_jobs', where: 'id = ?', whereArgs: [id]);
  }

  bool _isSyncing = false;

  Future<void> syncEverything() async {
    if (_isSyncing) return;

    final dynamic connectivityResult = await Connectivity().checkConnectivity();
    
    bool hasConnection = false;
    if (connectivityResult is List) {
      hasConnection = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
    } else {
      hasConnection = connectivityResult != ConnectivityResult.none;
    }

    if (!hasConnection) return;

    _isSyncing = true;
    debugPrint("--- INICIANDO SINCRONIZACIÓN OFFLINE ---");

    try {
      final pendingJobs = await getPendingJobs();
      for (var job in pendingJobs) {
        try {

          if (job.statusSynced == 0) {
            final res = await http.put(
              Uri.parse('${RequestServ.baseUrlNor}tickets/${job.ticketId}/status'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'status': job.phase, 'changedBy': job.changedBy}),
            ).timeout(const Duration(seconds: 10));

            if (res.statusCode == 200) {
              job.statusSynced = 1;
              await updateJob(job);
            }
          }

          List<dynamic> photos = jsonDecode(job.photosJson);
          bool allPhotosSynced = true;
          for (var photo in photos) {
            if (photo['synced'] == 0) {
              final request = http.MultipartRequest('POST', Uri.parse('${RequestServ.baseUrlNor}tickets/upload'));
              request.files.add(await http.MultipartFile.fromPath('file', photo['path']));
              final streamedRes = await request.send().timeout(const Duration(seconds: 30));
              final res = await http.Response.fromStream(streamedRes);

              if (res.statusCode == 200 || res.statusCode == 201) {
                final data = json.decode(res.body);
                String? remoteUrl = data['imageUrl']?.toString();
                if (remoteUrl != null) {
                  final resEvidence = await http.post(
                    Uri.parse('${RequestServ.baseUrlNor}tickets/${job.ticketId}/evidence'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'imageUrl': remoteUrl, 'phase': job.phase, 'sequence': photo['sequence']}),
                  ).timeout(const Duration(seconds: 10));

                  if (resEvidence.statusCode == 200 || resEvidence.statusCode == 201) {
                    photo['synced'] = 1;
                    photo['url'] = remoteUrl;
                    job.photosJson = jsonEncode(photos);
                    await updateJob(job);
                  }
                }
              } else {
                allPhotosSynced = false;
              }
            }
          }

          if (allPhotosSynced && job.formSynced == 0) {
            final res = await http.post(
              Uri.parse('${RequestServ.baseUrlNor}tickets/${job.ticketId}/form-data'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'formType': job.phase,
                'data': {
                  "technician": job.technicianName,
                  "unit": job.unitId,
                  "observations": job.observations,
                  "timestamp": job.timestamp
                }
              }),
            ).timeout(const Duration(seconds: 10));

            if (res.statusCode == 200 || res.statusCode == 201) {
              job.formSynced = 1;
              await updateJob(job);
            }
          }

          if (job.statusSynced == 1 && job.formSynced == 1 && allPhotosSynced) {
            await deleteJob(job.id!);
            debugPrint("Job ${job.id} completado y eliminado.");
          }
        } catch (e) {
          debugPrint("Error en Job ${job.id}: $e");
        }
      }
    } catch (e) {
      debugPrint("Error general en syncEverything: $e");
    } finally {
      _isSyncing = false;
      debugPrint("--- SINCRONIZACIÓN FINALIZADA ---");
    }
  }
}
