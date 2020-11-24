import {Pipe, PipeTransform} from '@angular/core';
import {I18n} from "./i18n";

/**
 * Pipe translating the input key.
 */
@Pipe({name: "i18n"})
export class I18nPipe implements PipeTransform {

	/**
	 * Transform the passed input value.
	 * @param value input value to transform
	 */
	public transform(value: string): string {
		return I18n.translate(value);
	}

}
