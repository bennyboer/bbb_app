/**
 * Translations for the app.
 */
export class I18n {

	/**
	 * German translations.
	 */
	private static readonly DE: any = {
		"welcome-msg": "Sie haben mehrere Optionen dem Meeting beizutreten!",
		"open-in-browser": "Im Browser öffnen",
		"open-in-app": "In der App öffnen",
		"install-app-notice-prefix": "Wenn Sie die App noch nicht haben, können Sie diese einfach über Google Play installieren, wenn Sie",
		"install-app-notice-link": "hier",
		"install-app-notice-postfix": "klicken!",
		"example-header": "Bitte geben Sie in der Addresszeile die gewünschte BBB Meeting URL mit an:",
		"example-header-accesscode": "Falls das Meeting durch ein Passwort geschützt ist, können Sie auch das in der Addresszeile wie folgt angeben:"
	};

	/**
	 * English translations.
	 */
	private static readonly EN: any = {
		"welcome-msg": "You have multiple options to join the meeting!",
		"open-in-browser": "Open in browser",
		"open-in-app": "Open in app",
		"install-app-notice-prefix": "If you do not have the app yet, you can get it on Google Play when you click",
		"install-app-notice-link": "here",
		"install-app-notice-postfix": "!",
		"example-header": "Please specify a BBB meeting URL in the address bar like the following example:",
		"example-header-accesscode": "In case the meeting is protected by an access code you can specify that as well like the following:",
	};

	/**
	 * Translation objects mapped by their locale name (for example 'en' or 'de').
	 */
	private static readonly TRANSLATIONS: any = {
		"de": I18n.DE,
		"en": I18n.EN
	};

	/**
	 * The default locale to use if the proper browser locale could not be determined.
	 */
	private static readonly DEFAULT_LOCALE: string = "en";

	/**
	 * The browsers locale.
	 */
	private static BROWSER_LOCALE: string;

	/**
	 * Get the translated value for the passed key.
	 * @param key to get translated value for
	 */
	public static translate(key: string): string {
		const locale: string = this.determineBrowserLocale();

		const translation: string = I18n.TRANSLATIONS[locale][key];
		if (!translation) {
			throw new Error(`No translation found for key: '${key}'`);
		}

		return translation;
	}

	/**
	 * Determine the browsers locale.
	 */
	private static determineBrowserLocale(): string {
		if (!this.BROWSER_LOCALE) {
			try {
				this.BROWSER_LOCALE = navigator.language
					.substring(0, 2)
					.toLowerCase();
			} catch (e) {
				this.BROWSER_LOCALE = I18n.DEFAULT_LOCALE;
			}
		}

		return this.BROWSER_LOCALE;
	}

}
