// 课表条目模型
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
  final String sectionText; // 如 01~02节
  final String weekText; // 如 第1周 或 1-12周/单双周
  final int dayOfWeek; // 1-7
  final int sectionIndex; // 第几大节（1-5），0 表示未知
}

// 成绩条目模型
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
  final String courseAttr; // 课程属性：必修/限选/任选/公选...
  final String courseNature; // 课程性质：公共课/平台课程/专业课程...
  final String generalType; // 通选课类别/其它分类
}

// 等级考试条目模型
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

// 培养方案条目模型
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

  final String index;         // 序号
  final String term;          // 开课学期
  final String courseCode;    // 课程编号
  final String courseName;    // 课程名称
  final String department;    // 开课单位
  final String credits;       // 学分
  final String totalHours;    // 总学时
  final String examType;      // 考核方式
  final String courseNature;  // 课程性质（公共课/平台课程/专业课程）
  final String courseAttr;    // 课程属性（必修/限选/任选）
  final String isExam;        // 是否考试
}

// 选课结果条目模型
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

  final String index;         // 序号
  final String courseName;    // 课程名称
  final String courseCode;    // 课程编号
  final String teacher;       // 上课教师
  final String totalHours;    // 总学时
  final String credits;       // 学分
  final String courseAttr;    // 课程属性
  final String courseNature;  // 课程性质
}

// 消息通知条目模型
class MessageNotificationEntry {
  MessageNotificationEntry({
    required this.index,
    required this.businessName,
    required this.content,
    required this.pushTime,
  });

  final String index;         // 序号
  final String businessName;  // 业务名称
  final String content;       // 消息内容
  final String pushTime;      // 推送时间
}

// 选课轮次条目模型
class CourseSelectionRoundEntry {
  CourseSelectionRoundEntry({
    required this.term,
    required this.name,
    required this.timeRange,
    this.jrxkParam1 = '',
    this.jrxkParam2 = '',
    this.jrxkParam3 = '',
  });

  final String term;          // 学年学期
  final String name;          // 选课名称
  final String timeRange;     // 选课时间
  final String jrxkParam1;   // jrxk 参数1
  final String jrxkParam2;   // jrxk 参数2 (选课轮次ID)
  final String jrxkParam3;   // jrxk 参数3
}

// 可选课程条目模型（选课中心 JSON API 返回）
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

  final String courseCode;      // 课程编号 (kch)
  final String courseName;      // 课程名称 (kcmc)
  final double credits;         // 学分 (xf)
  final int totalHours;         // 总学时 (zxs)
  final String teacher;         // 授课教师 (skls)
  final String classTime;       // 上课时间 (sksj)
  final String classLocation;   // 上课地点 (skdd)
  final String campus;          // 校区 (xqmc)
  final int enrolledCount;      // 已选人数 (xkrs)
  final int remainingCount;     // 剩余人数 (syrs)
  final int maxCapacity;        // 最大容量 (pkrs)
  final String category;        // 课程分类 (szkcflmc)
  final String courseType;      // 课程性质 (kcxzmc)
  final bool isNetworkCourse;   // 是否网络课
  final String jx0404id;        // 选课操作 ID
  final String jx02id;          // 课程方案 ID
  final bool isSelected;        // 是否已选 (xkzt=1)

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

