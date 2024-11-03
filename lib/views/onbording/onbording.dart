import 'package:achiva/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:achiva/views/onbording/content_model.dart';

class Onbording extends StatefulWidget {
  const Onbording({super.key});

  @override
  _OnbordingState createState() => _OnbordingState();
}

class _OnbordingState extends State<Onbording> {
  int currentIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
          ),
        ),
        child: SafeArea(
          // Added SafeArea to prevent notch overflow
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: contents.length,
                  onPageChanged: (int index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (_, i) {
                    return SingleChildScrollView(
                      // Added for scrolling on small devices
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.3, // Responsive height
                              child: Image.asset(
                                contents[i].image,
                                fit: BoxFit
                                    .contain, // Ensure image fits container
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              contents[i].title,
                              textAlign: TextAlign.center, // Center align title
                              style: const TextStyle(
                                color: Colors
                                    .white70, //  Colors.white70 or Colors.deepPurple or Colors.orange[800]
                                fontSize: 28, // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              contents[i].discription,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16, // Reduced font size
                                color: Colors.grey,
                                height:
                                    1.5, // Added line height for better readability
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20), // Added horizontal padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    contents.length,
                    (index) => buildDot(index, context),
                  ),
                ),
              ),
              Container(
                height: 60,
                margin: const EdgeInsets.all(40),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (currentIndex == contents.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(),
                        ),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve:
                            Curves.easeInOut, // Changed to smoother animation
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Theme.of(context)
                        .primaryColor, //Theme.of(context).primaryColor or Colors.orange[800]
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    currentIndex == contents.length - 1 ? "Continue" : "Next",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: currentIndex == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context)
            .primaryColor, //Theme.of(context).primaryColor or Colors.orange[800]
      ),
    );
  }
}
