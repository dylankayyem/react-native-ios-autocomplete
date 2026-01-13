# react-native-ios-autocomplete

Autocomplete address natively without any external API. This module is using MKLocalSearchCompleter Class in IOs, to provide suggestions to user entered address.

## Installation

```sh
npm install react-native-ios-autocomplete
```

## Usage

```js
import AddressAutocomplete from 'react-native-ios-autocomplete';

const suggestions = await AddressAutocomplete.getAddressSuggestions('Denver');
console.log(suggestions);

const details = await AddressAutocomplete.getAddressDetails('Denver');
console.log(details);

const reverseGeocodeResult = await AddressAutocomplete.reverseGeocodeLocation(
  22.16887,
  52.12333
);
console.log(reverseGeocodeResult);
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
