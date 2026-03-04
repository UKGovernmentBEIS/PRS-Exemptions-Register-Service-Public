import { createElement } from '@lwc/engine-dom';
import NavigateFromFlow from 'c/navigateFromFlow';

describe('c-navigate-from-flow', () => {

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

    it('should not navigate away when redirectUrl is not set', () => {
        // Arrange
        const element = createElement('c-navigate-from-flow', {
            is: NavigateFromFlow
        });
        element.redirectUrl = '';

        // Act
        document.body.appendChild(element);

        // Assert
        expect(window.location.href).toBe('');
    });

    it('should navigate away when redirectUrl is set', () => {
        // Arrange
        const element = createElement('c-navigate-from-flow', {
            is: NavigateFromFlow
        });
        element.redirectUrl = 'my-website.com';

        // Act
        document.body.appendChild(element);

        // Assert
       expect(window.location.href).toBe('/my-website.com');
    });
});