import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.blue;
      case Priority.high:
        return Colors.orange;
      case Priority.urgent:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case Priority.low:
        return Icons.arrow_downward;
      case Priority.medium:
        return Icons.horizontal_rule;
      case Priority.high:
        return Icons.arrow_upward;
      case Priority.urgent:
        return Icons.priority_high;
    }
  }
}

enum CargoType {
  general,
  refrigerated,
  hazardous,
  liquid,
  dry;

  String get displayName {
    switch (this) {
      case CargoType.general:
        return 'General';
      case CargoType.refrigerated:
        return 'Refrigerated';
      case CargoType.hazardous:
        return 'Hazardous';
      case CargoType.liquid:
        return 'Liquid';
      case CargoType.dry:
        return 'Dry';
    }
  }

  IconData get icon {
    switch (this) {
      case CargoType.general:
        return Icons.inventory;
      case CargoType.refrigerated:
        return Icons.ac_unit;
      case CargoType.hazardous:
        return Icons.warning;
      case CargoType.liquid:
        return Icons.water_drop;
      case CargoType.dry:
        return Icons.grain;
    }
  }

  Color get color {
    switch (this) {
      case CargoType.general:
        return Colors.blue;
      case CargoType.refrigerated:
        return Colors.cyan;
      case CargoType.hazardous:
        return Colors.red;
      case CargoType.liquid:
        return Colors.blue;
      case CargoType.dry:
        return Colors.brown;
    }
  }
}

enum ContainerStatus {
  inYard,
  inTransit,
  customClearance,
  readyForRelease,
  released,
  incidentReported;

  String get displayName {
    switch (this) {
      case ContainerStatus.inYard:
        return 'In Yard';
      case ContainerStatus.inTransit:
        return 'In Transit';
      case ContainerStatus.customClearance:
        return 'Custom Clearance';
      case ContainerStatus.readyForRelease:
        return 'Ready for Release';
      case ContainerStatus.released:
        return 'Released';
      case ContainerStatus.incidentReported:
        return 'Incident Reported';
    }
  }

  Color get color {
    switch (this) {
      case ContainerStatus.inYard:
        return Colors.blue;
      case ContainerStatus.inTransit:
        return Colors.orange;
      case ContainerStatus.customClearance:
        return Colors.purple;
      case ContainerStatus.readyForRelease:
        return Colors.green;
      case ContainerStatus.released:
        return Colors.grey;
      case ContainerStatus.incidentReported:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ContainerStatus.inYard:
        return Icons.storage;
      case ContainerStatus.inTransit:
        return Icons.local_shipping;
      case ContainerStatus.customClearance:
        return Icons.description;
      case ContainerStatus.readyForRelease:
        return Icons.check_circle;
      case ContainerStatus.released:
        return Icons.assignment_turned_in;
      case ContainerStatus.incidentReported:
        return Icons.warning;
    }
  }
}

class ContainerData {
  final String containerId;
  final String containerNumber;
  final String voyageId;
  final Priority priority;
  final DateTime dateCreated;
  final DateTime releaseDate;
  final CargoType cargoType;
  final ContainerStatus status;
  final String location;
  final String stackPosition;
  final int tierLevel;
  final String allocatedBayId;
  final String allocationStatus;
  final DateTime scannedAt;
  final DateTime lastUpdated;

  ContainerData({
    required this.containerId,
    required this.containerNumber,
    required this.voyageId,
    required this.priority,
    required this.dateCreated,
    required this.releaseDate,
    required this.cargoType,
    required this.status,
    required this.location,
    required this.stackPosition,
    required this.tierLevel,
    required this.allocatedBayId,
    required this.allocationStatus,
    required this.scannedAt,
    required this.lastUpdated,
  });

  // Convert from Firestore document
  factory ContainerData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    Priority parsePriority(String priority) {
      switch (priority.toLowerCase()) {
        case 'low': return Priority.low;
        case 'medium': return Priority.medium;
        case 'high': return Priority.high;
        case 'urgent': return Priority.urgent;
        default: return Priority.medium;
      }
    }
    
    CargoType parseCargoType(String cargoType) {
      switch (cargoType.toLowerCase()) {
        case 'general': return CargoType.general;
        case 'refrigerated': return CargoType.refrigerated;
        case 'hazardous': return CargoType.hazardous;
        case 'liquid': return CargoType.liquid;
        case 'dry': return CargoType.dry;
        default: return CargoType.general;
      }
    }

    ContainerStatus parseStatus(String status) {
      switch (status.toLowerCase()) {
        case 'in_yard':
        case 'in yard': return ContainerStatus.inYard;
        case 'in_transit':
        case 'in transit': return ContainerStatus.inTransit;
        case 'custom_clearance':
        case 'custom clearance': return ContainerStatus.customClearance;
        case 'ready_for_release':
        case 'ready for release': return ContainerStatus.readyForRelease;
        case 'released': return ContainerStatus.released;
        case 'incident_reported':
        case 'incident reported': return ContainerStatus.incidentReported;
        default: return ContainerStatus.inYard;
      }
    }
    
    return ContainerData(
      containerId: data['containerId'] ?? '',
      containerNumber: data['containerNumber'] ?? '',
      voyageId: data['voyageId'] ?? '',
      priority: parsePriority(data['priority'] ?? 'medium'),
      cargoType: parseCargoType(data['cargoType'] ?? 'general'),
      status: parseStatus(data['status'] ?? 'in_yard'),
      location: data['location'] ?? '',
      stackPosition: data['stackPosition'] ?? '',
      tierLevel: data['tierLevel'] ?? 1,
      allocatedBayId: data['allocatedBayId'] ?? '',
      allocationStatus: data['allocationStatus'] ?? 'pending',
      dateCreated: (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'containerId': containerId,
      'containerNumber': containerNumber,
      'voyageId': voyageId,
      'priority': _enumToString(priority),
      'cargoType': _enumToString(cargoType),
      'status': _enumToString(status),
      'location': location,
      'stackPosition': stackPosition,
      'tierLevel': tierLevel,
      'allocatedBayId': allocatedBayId,
      'allocationStatus': allocationStatus,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'releaseDate': Timestamp.fromDate(releaseDate),
      'scannedAt': Timestamp.fromDate(scannedAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  String _enumToString(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }
}