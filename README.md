# Ticket-Treak

## Configuration

API credentials are not stored in the source code. They are supplied at
compile time using Dart's `--dart-define` flags:

```sh
flutter run \
  --dart-define=AMADEUS_CLIENT_ID=your_amadeus_client_id \
  --dart-define=AMADEUS_CLIENT_SECRET=your_amadeus_client_secret \
  --dart-define=STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
```

The same flags must be passed to `flutter build`. Without them, the Amadeus
and Stripe integrations will fail to authenticate.

Notes:

- The Stripe **publishable** key (`pk_...`) remains in the source — it is
  designed to be public. Only the **secret** key (`sk_...`) must be provided
  via `--dart-define`, and in production it should live on a backend instead
  of in the app.
- Android release signing reads `key.properties` from the project root (not
  committed; see `.gitignore`) or the `ANDROID_UPLOAD_*` environment
  variables.
