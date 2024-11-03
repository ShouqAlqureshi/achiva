class UnbordingContent {
  String image;
  String title;
  String discription;

  UnbordingContent(
      {required this.image, required this.title, required this.discription});
}

List<UnbordingContent> contents = [
  UnbordingContent(
      title: 'Track Your Goals',
      image: 'lib/images/goals.png',
      discription:
          "Set and track your personal goals with dynamic countdowns and progress tracking. "
          "Break down large goals into manageable tasks and celebrate every milestone "
          "on your journey to success. Watch your progress grow in real-time!"),
  UnbordingContent(
      title: 'Compete & Connect',
      image: 'lib/images/ranking.png',
      discription:
          "Join a motivating community of goal-achievers! Compare your productivity "
          "with friends on our dynamic leaderboard and share your accomplishments "
          "in the social feed. Healthy competition leads to better results!"),
  UnbordingContent(
      title: 'Collaborative Goals',
      image: 'lib/images/collaborate.png',
      discription:
          "Team up with friends for shared goals and keep each other accountable. "
          "View your friends' progress updates and celebrate achievements together. "
          "Success is better when shared!"),
  UnbordingContent(
      title: 'Track Productivity',
      image: 'lib/images/productivity.png',
      discription:
          "Monitor your daily productivity with intuitive analytics and insights. "
          "Compare your performance trends with friends and identify your peak "
          "productivity patterns to achieve more each day!"),
  UnbordingContent(
      title: 'Achieve Together',
      image: 'lib/images/social.png',
      discription:
          "Join goal-oriented communitie, share your accomplished tasks and tips, and get inspired "
          "by others' success stories. Transform your goal-setting journey into an "
          "engaging social experience!"),
];
