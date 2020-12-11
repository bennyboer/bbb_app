import {Component} from "@angular/core";
import {DomSanitizer, SafeUrl} from "@angular/platform-browser";

@Component({
	selector: "app-root",
	templateUrl: "./app.component.html",
	styleUrls: ["./app.component.scss"]
})
export class AppComponent {

	/**
	 * Deep linking scheme used to open the BBB app.
	 */
	private static readonly BBB_APP_SCHEME: string = "bbb-app";

	/**
	 * Meeting URL to attend.
	 */
	private _meetingUrl: string | null = null;

	/**
	 * Optional access code of the meeting.
	 */
	private _accessCode: string | null = null;

	/**
	 * All found URL parameter.
	 */
	private readonly _urlParams: Map<string, string> = new Map<string, string>();

	constructor(
		private readonly sanitizer: DomSanitizer
	) {
		const urlParams = new URLSearchParams(window.location.search);

		const meetingUrlParam = urlParams.get("target");
		if (!!meetingUrlParam && meetingUrlParam.length > 0) {
			this._meetingUrl = meetingUrlParam;
		}

		const accessCodeParam = urlParams.get("accessCode");
		if (!!accessCodeParam && accessCodeParam.length > 0) {
			this._accessCode = accessCodeParam;
		}

		urlParams.forEach((value, key) => {
			if (key !== "target" && key != "accessCode") {
				this._urlParams.set(key, value);
			}
		});
	}

	/**
	 * Whether there is a meeting URl currently specified in the URL.
	 */
	public get hasMeetingUrl(): boolean {
		return !!this._meetingUrl;
	}

	/**
	 * Get the base URL of the application.
	 */
	public get baseUrl(): string {
		const url: Location = window.location;

		return `${url.protocol}//${url.host}/`;
	}

	/**
	 * Get the open in browser link.
	 */
	public get openInBrowserLink(): string {
		const url: URL = new URL(this._meetingUrl);
		const keys: string[] = [];
		if (!!url.searchParams) {
			url.searchParams.forEach((value, key) => {
				keys.push(key);
			});
		}

		let hasFirstParameter: boolean = keys.length > 0;

		let result: string = this._meetingUrl;
		for (const entry of this._urlParams.entries()) {
			const key: string = entry[0];
			const value: string = entry[1];

			if (hasFirstParameter) {
				result += `&${key}=${value}`;
			} else {
				result += `?${key}=${value}`;

				hasFirstParameter = true;
			}
		}

		return result;
	}

	/**
	 * Get the open in app link.
	 */
	public get openInAppLink(): SafeUrl {
		const meetingURL: string = this.openInBrowserLink;

		const url: URL = new URL(meetingURL);
		const normalizedMeetingURL: string = meetingURL.replace("https://", "");

		const keys: string[] = [];
		if (!!url.searchParams) {
			url.searchParams.forEach((value, key) => {
				keys.push(key);
			});
		}

		const hasFirstParameter: boolean = keys.length > 0;
		console.log(keys);

		let result: string = `${AppComponent.BBB_APP_SCHEME}://${normalizedMeetingURL}`;
		if (!!this._accessCode) {
			result += `${hasFirstParameter ? "&" : "?"}accessCode=${this._accessCode}`;
		}

		return this.sanitizer.bypassSecurityTrustUrl(result);
	}

}
