import {BrowserModule} from "@angular/platform-browser";
import {NgModule} from "@angular/core";

import {AppComponent} from "./app.component";
import {I18nPipe} from "../i18n/i18n-pipe";

@NgModule({
	declarations: [
		AppComponent,
		I18nPipe
	],
	imports: [
		BrowserModule
	],
	providers: [],
	bootstrap: [AppComponent]
})
export class AppModule {
}
