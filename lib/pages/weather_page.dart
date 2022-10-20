import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:weather_app_batch05/provider/weather_provider.dart';
import 'package:weather_app_batch05/utils/constants.dart';
import 'package:weather_app_batch05/utils/helper_function.dart';
import 'package:weather_app_batch05/utils/location_utils.dart';
import 'package:weather_app_batch05/utils/text_styles.dart';

import 'settings_page.dart';

class WeatherPage extends StatefulWidget {
  static const String routeName = '/';
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late WeatherProvider provider;
  bool isFirst = true;
  Timer? timer;


  @override
  void didChangeDependencies() {
    if(isFirst) {
      provider = Provider.of<WeatherProvider>(context);
      _getData();
      isFirst = false;
    }
    super.didChangeDependencies();
  }

  _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      //print('timer started');
      final isOn = await Geolocator.isLocationServiceEnabled();
      if(isOn) {
        _stopTimer();
        _getData();
      }
    });
  }

  _stopTimer() {
    if(timer != null) {
      timer!.cancel();
    }
  }

  _getData() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isLocationEnabled) {
      showMsgWithAction(
          context: context,
          msg: 'Please turn on location',
          callback: () async {
            _startTimer();
            final status = await Geolocator.openLocationSettings();
            print(status);
          });
      return;
    }
    try{
      final position = await determinePosition();
      provider.setNewLocation(position.latitude, position.longitude);
      provider.setTempUnit(await provider.getPreferenceTempUnitValue());
      provider.getWeatherData();
    }catch(error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather'),
        actions: [
          IconButton(
            onPressed: () {
              _getData();
            },
            icon: const Icon(Icons.my_location),
          ),
          IconButton(
            onPressed: () async {
              final result = await showSearch(context: context, delegate: _CitySearchDelegate());
              if(result != null && result.isNotEmpty) {
                //print(result);
                provider.convertAddressToLatLng(result);
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, SettingsPage.routeName),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: provider.hasDataLoaded ? ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _currentWeatherSection(),
            _forecastWeatherSection(),
          ],
        ) :
        const Text('Please wait...', style: txtNormal16,),
      ),
    );
  }

  Widget _currentWeatherSection() {
    final response = provider.currentResponseModel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(getFormattedDateTime(response!.dt!, 'MMM dd, yyyy'), style: txtDateHeader18,),
        Text('${response.name},${response.sys!.country}', style: txtAddress24,),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('$iconPrefix${response.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
              Text('${response!.main!.temp!.round()}$degree${provider.unitSymbol}', style: txtTempBig80,)
            ],
          ),
        ),
        Wrap(
          children: [
            Text('feels like ${response.main!.feelsLike!.round()}$degree${provider.unitSymbol}', style: txtNormal16,),
            const SizedBox(width: 10,),
            Text('${response.weather![0].main}, ${response.weather![0].description}', style: txtNormal16,)
          ],
        ),
        const SizedBox(height: 20,),
        Wrap(
          children: [
            Text('Humidity ${response.main!.humidity}%', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Pressure ${response.main!.pressure}hPa', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Visibility ${response.visibility}meter', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Wind ${response.wind!.speed}m/s', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Degree ${response.wind!.deg}$degree', style: txtNormal16White54,)
          ],
        ),

        const SizedBox(height: 20,),
        Wrap(
          children: [
            Text('Sunrise ${getFormattedDateTime(response.sys!.sunrise!, 'hh:mm a')}', style: txtNormal16,),
            const SizedBox(width: 10,),
            Text('Sunset ${getFormattedDateTime(response.sys!.sunset!, 'hh:mm a')}', style: txtNormal16,),

            const SizedBox(width: 10,),

          ],
        ),
      ],
    );
  }

  Widget _forecastWeatherSection() {
    return Center();
  }


}

class _CitySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        close(context, query);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty ? cities :
        cities.where((city) =>
            city.toLowerCase().startsWith(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredList[index]),
        onTap: () {
          query = filteredList[index];
          close(context, query);
        },
      ),
    );
  }

}
