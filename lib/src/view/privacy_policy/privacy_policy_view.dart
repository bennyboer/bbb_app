import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// View displaying the privacy policy of the app.
class PrivacyPolicyView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PrivacyPolicyViewState();
}

/// State of the privacy policy view.
class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  /// Future loading the privacy policy content.
  Future<String> _loadPrivacyPolicyFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: _buildContent(context),
      ),
    );
  }

  /// Build the application bar for the view.
  Widget _buildAppBar(BuildContext context) => AppBar(
        title: Text(AppLocalizations.of(context).get("privacy-policy.title")),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          tooltip: AppLocalizations.of(context).get("back"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );

  /// Build the privacy statement content.
  Widget _buildContent(BuildContext context) {
    if (_loadPrivacyPolicyFuture == null) {
      _loadPrivacyPolicyFuture = _getPrivacyPolicyStatementContent();
    }

    return FutureBuilder(
      future: _loadPrivacyPolicyFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          String content = snapshot.data;

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 40.0,
              horizontal: 40.0,
            ),
            child: MarkdownBody(
              data: content,
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 30.0),
            child: Text(
              AppLocalizations.of(context).get("load-error"),
            ),
          );
        } else {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 30.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  /// Assumes the given path is a text-file-asset.
  Future<String> _getPrivacyPolicyStatementContent() async {
    String languageCode =
        Localizations.localeOf(context).languageCode.substring(0, 2);
    if (languageCode == null ||
        (languageCode != "de" && languageCode != "en")) {
      languageCode = "en";
    }

    return await rootBundle
        .loadString("assets/privacy_policy/$languageCode.md");
  }
}
