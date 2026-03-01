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

