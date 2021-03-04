import 'package:bbb_app/src/locale/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const GITHUB_REPO_URL = "https://github.com/bennyboer/bbb_app";

/// Widget displaying a quick note on the app.
class AppNoticeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context).get("app.notice"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyText1.color.withOpacity(0.5),
              fontSize: 12.0,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await canLaunch(GITHUB_REPO_URL)
                ? await launch(GITHUB_REPO_URL)
                : throw 'Could not launch $GITHUB_REPO_URL';
          },
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0), color: Colors.white),
            child: Image.asset(
              "assets/GitHub_Logo.png",
              height: 30.0,
            ),
          ),
        ),
      ],
    );
  }
}
