import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A reusable TextFormField with a microphone suffixIcon for voice-to-text input.
class VoiceTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final String? initialValue;

  const VoiceTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.helperText,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<VoiceTextFormField> createState() => _VoiceTextFormFieldState();
}

class _VoiceTextFormFieldState extends State<VoiceTextFormField> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            widget.controller.text = result.recognizedWords;
            widget.onChanged?.call(result.recognizedWords);
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(Icons.mic, color: _isListening ? Colors.red : Colors.grey),
          onPressed: _isListening ? _stopListening : _startListening,
        ),
      ),
    );
  }
}
