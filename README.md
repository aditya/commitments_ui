# Overview #

This is the superforker root package for installing a commitments
server.

# Requirements #
You need need `node`.

# Get Started #

* Clone me
* Go into the directory you cloned
* Get started with:
    ```
    npm set domain localhost:8080
    npm install
    npm start
    ```

# Settings #

* `domain`
    This goes into urls, exposed as the environmenr variable `DOMAIN` to
    superforker scripts.
    If you want to run and test locally:
    ```
    npm set domain localhost:8080
    ```
* AWS
    Commitments uses SES, so if you want email to send, you'll need
    `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID` set before you
    start, as well as SES enabled on your account.

# Hacking in a user without email for testing

* Put in your email address as join
* Go into ~/var/commitments/tokens/token
* Rename the token to xxx
* Click on my picture on the home page, you'll be you
