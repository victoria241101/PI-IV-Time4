import 'package:flutter/material.dart';
import 'package:pet_care/screens/tutor/consultas_tutor.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConsultasTutor(
        consultas: [],
        nomesPets: ['Mel', 'Luna'],
      ),
    ),
  );
}