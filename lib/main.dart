import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app_batch05/provider/weather_provider.dart';
import 'pages/settings_page.dart';
import 'pages/weather_page.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => WeatherProvider(),
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'MerriweatherSans',
        primarySwatch: Colors.blue,
      ),
      initialRoute: WeatherPage.routeName,
      routes: {
        WeatherPage.routeName : (_) => WeatherPage(),
        SettingsPage.routeName : (_) => SettingsPage(),
      },
    );
  }
}

