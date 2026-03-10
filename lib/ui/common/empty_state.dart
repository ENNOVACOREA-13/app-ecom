import 'package:flutter/material.dart';
class EmptyState extends StatelessWidget{
  final String texto;
  const EmptyState(this.texto, {super.key});
  @override Widget build(BuildContext c)=> Center(child: Text(texto));
}
