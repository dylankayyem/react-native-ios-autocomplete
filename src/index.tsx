import { NativeModules, Platform } from 'react-native';

export type AddressDetails = {
  // ✅ legacy fields (still returned)
  title: string;
  coordinate: {
    latitude: number;
    longitude: number;
  };
  region: {
    longitude: number;
    latitude: number;
    longitudeDelta: number;
    latitudeDelta: number;
  };

  // ✅ new fields (added)
  location?: {
    latitude: number;
    longitude: number;
  };

  addressRepresentations?: string[];

  address?: {
    street?: string;
    house?: string;
    city?: string;
    region?: string; // state/admin area
    postalCode?: string;
    country?: string;
    isoCountryCode?: string;
  };

  kind?: 'poi' | 'address';
  poiCategory?: string | null;

  phoneNumber?: string | null;
  url?: string | null;
  timeZone?: string | null;
};

export type ReverseGeocodeResult = {
  street: string;
  house: string;
  zip: number;
  country: string;
  city: string;
};

const NativeAddressAutocomplete = NativeModules.AddressAutocomplete;
const NativeGeocode = NativeModules.ReverseGeocode;

class AddressAutocomplete {
  static getAddressDetails = async (
    address: string
  ): Promise<AddressDetails> => {
    const promise = new Promise<AddressDetails>(async (resolve, reject) => {
      if (Platform.OS === 'android') {
        reject('Only IOs supported.');
      }
      if (address.length > 0) {
        try {
          const details = await NativeAddressAutocomplete.getAddressDetails(
            address
          );
          resolve(details);
        } catch (err) {
          reject(err);
        }
      } else {
        reject('Address length should be greater than 0');
      }
    });
    return promise;
  };

  static getAddressSuggestions = async (address: string): Promise<string[]> => {
    const promise = new Promise<string[]>(async (resolve, reject) => {
      if (Platform.OS === 'android') {
        reject('Only IOs supported.');
      }
      if (address.length > 0) {
        try {
          const suggestions =
            await NativeAddressAutocomplete.getAddressSuggestions(address);
          resolve(suggestions);
        } catch (err) {
          reject(err);
        }
      } else {
        reject('Address length should be greater than 0');
      }
    });
    return promise;
  };

  static reverseGeocodeLocation = async (
    longitude: number,
    latitude: number
  ): Promise<ReverseGeocodeResult> => {
    const promise = new Promise<ReverseGeocodeResult>(
      async (resolve, reject) => {
        if (Platform.OS === 'android') {
          reject('Only IOs supported.');
        }
        if (latitude && longitude) {
          try {
            const geocode = await NativeGeocode.reverseGeocodeLocation(
              longitude,
              latitude
            );
            resolve(geocode);
          } catch (err) {
            reject(err);
          }
        } else {
          reject('No latitude or longitude provided');
        }
      }
    );
    return promise;
  };
}

export default AddressAutocomplete;
