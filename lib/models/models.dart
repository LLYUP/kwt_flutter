class TimetableEntry {
  TimetableEntry({
    required this.courseName,
    required this.teacher,
    required this.credits,
    required this.location,
    required this.sectionText,
    required this.weekText,
    required this.dayOfWeek,
    this.sectionIndex = 0,
  });

  final String courseName;
  final String teacher;
  final String credits;
  final String location;
  final String sectionText;
  final String weekText;
  final int dayOfWeek;
  final int sectionIndex;
}

class GradeEntry {
  GradeEntry({
    required this.term,
    required this.courseCode,
    required this.courseName,
    required this.score,
    required this.scoreFlag,
    required this.credit,
    required this.totalHours,
    required this.gpa,
    required this.examType,
    required this.examNature,
    required this.courseAttr,
    required this.courseNature,
    required this.generalType,
  });

  final String term;
  final String courseCode;
  final String courseName;
  final String score;
  final String scoreFlag;
  final String credit;
  final String totalHours;
  final String gpa;
  final String examType;
  final String examNature;
  final String courseAttr;
  final String courseNature;
  final String generalType;
}

class ExamLevelEntry {
  ExamLevelEntry({
    required this.course,
    required this.writtenScore,
    required this.labScore,
    required this.totalScore,
    required this.writtenLevel,
    required this.labLevel,
    required this.totalLevel,
    required this.startDate,
    required this.endDate,
  });

  final String course;
  final String writtenScore;
  final String labScore;
  final String totalScore;
  final String writtenLevel;
  final String labLevel;
  final String totalLevel;
  final String startDate;
  final String endDate;
}// 教材信息条目模型
class TextbookEntry {
  TextbookEntry({
    required this.courseCode,
    required this.courseName,
    required this.isbn,
    required this.textbookName,
    required this.price,
    required this.edition,
    required this.publisher,
    required this.teacher,
    required this.department,
    required this.orderStatus,
  });

  final String courseCode;
  final String courseName;
  final String isbn;
  final String textbookName;
  final String price;
  final String edition;
  final String publisher;
  final String teacher;
  final String department;
  final String orderStatus;
}

class TrainingPlanEntry {
  TrainingPlanEntry({
    required this.index,
    required this.term,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.credits,
    required this.totalHours,
    required this.examType,
    required this.courseNature,
    required this.courseAttr,
    required this.isExam,
  });

  final String index;
  final String term;
  final String courseCode;
  final String courseName;
  final String department;
  final String credits;
  final String totalHours;
  final String examType;
  final String courseNature;
  final String courseAttr;
  final String isExam;
}

class CourseSelectionEntry {
  CourseSelectionEntry({
    required this.index,
    required this.courseName,
    required this.courseCode,
    required this.teacher,
    required this.totalHours,
    required this.credits,
    required this.courseAttr,
    required this.courseNature,
  });

  final String index;
  final String courseName;
  final String courseCode;
  final String teacher;
  final String totalHours;
  final String credits;
  final String courseAttr;
  final String courseNature;
}

class MessageNotificationEntry {
  MessageNotificationEntry({
    required this.index,
    required this.businessName,
    required this.content,
    required this.pushTime,
  });

  final String index;
  final String businessName;
  final String content;
  final String pushTime;
}

class CourseSelectionRoundEntry {
  CourseSelectionRoundEntry({
    required this.term,
    required this.name,
    required this.timeRange,
    this.jrxkParam1 = '',
    this.jrxkParam2 = '',
    this.jrxkParam3 = '',
  });

  final String term;
  final String name;
  final String timeRange;
  final String jrxkParam1;
  final String jrxkParam2;
  final String jrxkParam3;
}

class ElectiveCourseEntry {
  ElectiveCourseEntry({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.totalHours,
    required this.teacher,
    required this.classTime,
    required this.classLocation,
    required this.campus,
    required this.enrolledCount,
    required this.remainingCount,
    required this.maxCapacity,
    required this.category,
    required this.courseType,
    required this.isNetworkCourse,
    required this.jx0404id,
    required this.jx02id,
    this.isSelected = false,
  });

  final String courseCode;
  final String courseName;
  final double credits;
  final int totalHours;
  final String teacher;
  final String classTime;
  final String classLocation;
  final String campus;
  final int enrolledCount;
  final int remainingCount;
  final int maxCapacity;
  final String category;
  final String courseType;
  final bool isNetworkCourse;
  final String jx0404id;
  final String jx02id;
  final bool isSelected;

  factory ElectiveCourseEntry.fromJson(Map<String, dynamic> json) {
    final syrsRaw = json['syrs'];
    int syrs = 0;
    if (syrsRaw is int) {
      syrs = syrsRaw;
    } else if (syrsRaw is String) {
      syrs = int.tryParse(syrsRaw) ?? 0;
    }

    return ElectiveCourseEntry(
      courseCode: json['kch']?.toString() ?? '',
      courseName: json['kcmc']?.toString() ?? '',
      credits: (json['xf'] is num) ? (json['xf'] as num).toDouble() : double.tryParse(json['xf']?.toString() ?? '0') ?? 0,
      totalHours: (json['zxs'] is int) ? json['zxs'] : int.tryParse(json['zxs']?.toString() ?? '0') ?? 0,
      teacher: (json['skls']?.toString() ?? '').replaceAll('&nbsp;', '').trim(),
      classTime: (json['sksj']?.toString() ?? '').replaceAll('&nbsp;', '').trim(),
      classLocation: (json['skdd']?.toString() ?? '').replaceAll('&nbsp;', '').trim(),
      campus: json['xqmc']?.toString() ?? '',
      enrolledCount: (json['xkrs'] is int) ? json['xkrs'] : int.tryParse(json['xkrs']?.toString() ?? '0') ?? 0,
      remainingCount: syrs,
      maxCapacity: (json['pkrs'] is int) ? json['pkrs'] : int.tryParse(json['pkrs']?.toString() ?? '0') ?? 0,
      category: json['szkcflmc']?.toString() ?? '',
      courseType: json['kcxzmc']?.toString() ?? '',
      isNetworkCourse: json['isnetworkcourse'] == '是',
      jx0404id: json['jx0404id']?.toString() ?? '',
      jx02id: json['jx02id']?.toString() ?? '',
      isSelected: json['xkzt']?.toString() != null && json['xkzt'].toString() != '0' && json['xkzt'].toString().isNotEmpty,
    );
  }
}

