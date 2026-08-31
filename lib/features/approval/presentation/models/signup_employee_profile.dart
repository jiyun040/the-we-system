class SignupEmployeeProfile {
  const SignupEmployeeProfile({
    required this.name,
    required this.department,
    required this.position,
  });

  final String name;
  final String department;
  final String position;
}

const signupEmployeeProfiles = [
  SignupEmployeeProfile(name: '조상훈', department: '대표이사', position: '대표'),
  SignupEmployeeProfile(name: '조세훈', department: '기술부', position: '전무'),
  SignupEmployeeProfile(name: '김현정', department: '공무', position: '대리'),
  SignupEmployeeProfile(name: '김효민', department: '경리부', position: '대리'),
  SignupEmployeeProfile(name: '정효정', department: '관리부', position: '이사'),
  SignupEmployeeProfile(name: '송형숙', department: '관리부', position: '부장'),
  SignupEmployeeProfile(name: '조용덕', department: '연구소', position: '부장'),
];

const signupDepartments = ['대표이사', '기술부', '공무', '경리부', '관리부', '연구소'];

SignupEmployeeProfile? signupProfileForName(String name) {
  final normalizedName = name.trim();
  for (final profile in signupEmployeeProfiles) {
    if (profile.name == normalizedName) return profile;
  }
  return null;
}

String signupPositionFor({required String department, required String name}) {
  final departmentProfiles = signupEmployeeProfiles
      .where((profile) => profile.department == department)
      .toList();

  if (departmentProfiles.length == 1) {
    return departmentProfiles.single.position;
  }

  final normalizedName = name.trim();
  for (final profile in departmentProfiles) {
    if (profile.name == normalizedName) return profile.position;
  }
  return '';
}

String? validateSignupEmployee({
  required String name,
  required String department,
  required String position,
}) {
  final profile = signupProfileForName(name);
  if (profile == null) {
    return '등록된 구성원 이름을 정확히 입력해 주세요.';
  }
  if (profile.department != department) {
    return '${profile.name}님의 부서는 ${profile.department}입니다.';
  }
  if (profile.position != position) {
    return '${profile.name}님의 직책은 ${profile.position}입니다.';
  }
  return null;
}
