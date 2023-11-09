// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  bool isConnected = false;
  bool? isOn;

  int temperature = 0;
  int humidity = 0;

  int counterConnection = 0;

  bool disconnect = false;
  bool error = false;
  bool notWorking = false;
  String serverUrl = '';

  final TextEditingController _serverAddressController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    error = false;
  }

  void getTemperatureAndHumidity() async {
    if (disconnect) return;
    try {
      notWorking = false;
      Response response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      ).get('$serverUrl/lesensor');
      setState(() {
        temperature = response.data['temperatura'];
        humidity = response.data['umidade'];
        isConnected = true;
      });
      setState(() {
        error = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isConnected = false;
        counterConnection++;
        error = true;
      });
      print(e);
    } finally {
      if (counterConnection >= 3) {
        setState(() {
          counterConnection = 0;
          disconnect = true;
          error = false;
          notWorking = true;
        });
      }
      await Future.delayed(const Duration(seconds: 1));
      getTemperatureAndHumidity();
    }
  }

  void ledOn() async {
    try {
      await Dio().get('$serverUrl/ledon');
      setState(() {
        isOn = true;
      });
    } catch (e) {
      print(e);
      await showDialog(
        context: context,
        builder: (BuildContext context) => errorDialog(),
      );
    }
  }

  void ledOff() async {
    try {
      await Dio().get('$serverUrl/ledoff');
      setState(() {
        isOn = false;
      });
    } catch (e) {
      print(e);
      await showDialog(
        context: context,
        builder: (BuildContext context) => errorDialog(),
      );
    }
  }

  Widget errorDialog() {
    return AlertDialog(
      title: const Text('Erro'),
      content: const Text('Não foi possível conectar ao servidor.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Ok'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Trabalho IoT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text.rich(
              TextSpan(
                text: 'Status de conexão: ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: isConnected ? 'Conectado' : 'Desconectado',
                    style: TextStyle(
                      color: isConnected
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Flexible(
                  child: TextFormField(
                    controller: _serverAddressController,
                    decoration: const InputDecoration(
                      hintText: 'Endereço do servidor',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isConnected ? 'Desconectar' : 'Conectar',
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (isConnected) {
                      setState(() {
                        disconnect = true;
                        serverUrl = '';
                        isConnected = false;
                      });
                      return;
                    }
                    setState(() {
                      disconnect = false;
                      serverUrl = _serverAddressController.text;
                      getTemperatureAndHumidity();
                    });
                  },
                  icon: Icon(
                    isConnected ? Icons.close : Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (error) ...[
              const SizedBox(height: 20),
              const Text('Erro na conexão, verifique o endereço do servidor.',
                  style: TextStyle(color: Colors.red)),
              Row(
                children: [
                  const SizedBox(
                    height: 10,
                    width: 10,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Tentando reconectar... ($counterConnection / 3)',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            if (notWorking) ...[
              const SizedBox(height: 20),
              const Text('Não foi possível conectar ao servidor.',
                  style: TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOn == true
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                  ),
                  onPressed: () {
                    ledOn();
                  },
                  child: Text(
                    'Ligar',
                    style: TextStyle(
                        color: isOn == true
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOn == false
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    onPressed: () {
                      ledOff();
                    },
                    child: Text(
                      'Desligar',
                      style: TextStyle(
                          color: isOn == false
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                text: 'Temperatura: ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: temperature.toString(),
                    style: TextStyle(
                      color: isConnected
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const TextSpan(text: '°C')
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: 'Umidade: ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: humidity.toString(),
                    style: TextStyle(
                      color: isConnected
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),      
                  ),
                 const TextSpan(text: '%')
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
