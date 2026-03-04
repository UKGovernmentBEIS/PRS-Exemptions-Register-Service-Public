import { createElement } from '@lwc/engine-dom';
import GdsButton from 'c/gdsButton';

describe('c-gds-button', () => {
    beforeEach(() => {
        delete window.location;
        window.location = {
            assign: jest.fn(),
            href: '',
            origin: ''
        };
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should not navigate away when no communityLink set', () => {
        // Arrange
        const element = createElement('c-gds-button', {
            is: GdsButton
        });
        element.communityLink = '';
        const navigateHandler = jest.fn();
        element.addEventListener('navigate', navigateHandler);
        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('.govuk-button');
        const navigateEvt = new CustomEvent('click');
        button.dispatchEvent(navigateEvt);

        // Assert
        expect(window.location.href).toBe('');
        expect(navigateHandler).toHaveBeenCalledTimes(0);
    });

    it('should navigate away when externalLink is true', () => {
        // Arrange
        const element = createElement('c-gds-button', {
            is: GdsButton
        });
        element.communityLink = 'my-website.com';
        element.externalLink = true;
        const navigateHandler = jest.fn();
        element.addEventListener('navigate', navigateHandler);
        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('.govuk-button');
        const navigateEvt = new CustomEvent('click');
        button.dispatchEvent(navigateEvt);

        // Assert
        expect(window.location.href).toBe('/my-website.com');
        expect(navigateHandler).toHaveBeenCalledTimes(0);
    });

    it('should navigate to community page when externalLink is false', async () => {
        // Arrange
        const element = createElement('c-gds-button', {
            is: GdsButton
        });
        element.communityLink = 'PRSEExemptionsRegister/account-registration';
        element.externalLink = false;
        document.body.appendChild(element);
        const navigateHandler = jest.fn();
        element.addEventListener('navigate', navigateHandler);
       

        // Act
        const button = element.shadowRoot.querySelector('.govuk-button');
        const navigateEvt = new CustomEvent('click');
        button.dispatchEvent(navigateEvt);

        // Assert
        expect(window.location.href).toBe('');
        expect(navigateHandler).toHaveBeenCalledTimes(1);
        const navigateArgument = navigateHandler.mock.calls[0][0].detail.pageReference;
        expect(navigateArgument).toBeTruthy();
        expect(navigateArgument.type).toBe('comm__namedPage');
        expect(navigateArgument.attributes.name).toBe('PRSEExemptionsRegister/account-registration');
    });
});