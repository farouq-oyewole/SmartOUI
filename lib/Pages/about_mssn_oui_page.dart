import 'package:flutter/material.dart';

class AboutMssnOuiPage extends StatelessWidget {
  const AboutMssnOuiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF1B5E20);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About MSSN OUI"),
        backgroundColor: primaryGreen,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.grey[900]!]
                // ignore: deprecated_member_use
                : [primaryGreen.withOpacity(0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: const [
            Text(
              "Muslim Students’ Society of Nigeria (MSSN), Oduduwa University Chapter",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14),
            Text(
              "MSSN OUI is a vibrant Islamic body established to unite and strengthen the Muslim community within Oduduwa University. Our mission is to guide Muslim students toward the correct understanding of Islam, foster brotherhood, and promote moral excellence through education and collective worship.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 20),
            Text(
              "Our Goals",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              "• To bring Muslims together to learn about their Deen (Islam).\n"
              "• To promote unity, love, and collaboration among Muslim students.\n"
              "• To organize educational, spiritual, and social programs that uplift the Ummah.\n"
              "• To serve as a platform for mentorship, guidance, and Dawah on campus.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 20),
            Text(
              "About the MSSN App",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              "The MSSN OUI App was built to make engagement easier — allowing members to view donation history, earn credit points, participate in verified transactions, and access community updates all in one place. Your contributions are securely stored and reflected as a ‘credit score’, motivating consistent support for the Ummah.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 20),
            Text(
              "We also use this platform to share upcoming events, campaigns, and updates about MSSN OUI activities — bridging the gap between students and the society’s leadership through technology.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 30),
            Text(
              "Together, we aim to strengthen faith, build leadership, and foster unity within Oduduwa University — making every student a beacon of Islamic excellence.",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
