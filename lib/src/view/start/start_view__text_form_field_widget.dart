import 'package:flutter/material.dart';

class StartViewTextFormField extends StatefulWidget {

  StartViewTextFormField({
    Key key,
    this.onChanged,
    this.validator,
    this.controller,
    this.hintText,
    this.prefixIcon
  }) : super(key: key);

  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  final TextEditingController controller;
  final String hintText;
  final Icon prefixIcon;

  @override
  State<StatefulWidget> createState() => _StartViewTextFormField();
}

class _StartViewTextFormField extends State<StartViewTextFormField> {
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _showClearButton = widget.controller.text.length > 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        style: TextStyle(fontSize: 20.0),
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          prefixIcon: widget.prefixIcon,
          suffixIcon: _getClearButton(),
        ),
        onChanged: widget.onChanged,
        validator: widget.validator,
        controller: widget.controller,
      ),
    );
  }

  Widget _getClearButton() {
    if (!_showClearButton) { return null; }

    return IconButton(
      padding: EdgeInsets.all(0),
      onPressed: () => widget.controller.clear(),
      icon: Icon(Icons.clear),
    );
  }
}
