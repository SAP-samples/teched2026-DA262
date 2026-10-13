# DA262 -  Get hands-on with tabular AI- and forecasting-models in SAP HANA Cloud

## Description

This repository contains the material for the SAP TechEd 2025 Hands-on Workshop __Get hands-on with tabular AI- and forecasting-models in SAP HANA Cloud__ (Session-ID DA262). 

## Overview

Explore how to leverage key new SAP HANA Cloud database AI capabilities for relational data, like how to generate on-the-fly predictions using tabular AI  models like SAP-RPT or how to generate ad-hoc forecasts using the new time series foundation model variant SAP-RPT-TS. Remain inspired by recent innovations from the Predictive Analysis Library (PAL) like processing raw text columns in AutoML models or how to build multi-target classification models with sets of dual-role features, being feature and target at the same time.

## Requirements

The technical requirements to complete the exercises in this repository, including hardware and software specifications are taken care of by the provided systems used for the in-person Hands-on Workshop.  You will be leveraging:
- Visual Studio Code, using Python environment and SQL via the SAP HANA Database Explorer extension, 
- connecting to a SAP HANA Cloud instance with the ScriptServer and NLP services activated
- connecting to an AI Core orchestration service and a SAP-RPT service instance using remote sources from SAP HANA Cloud

The remaining  _setup and configuration tasks_ are outlined in the [Getting Started - prepare your local VS Code environment](exercises/ex0/) section.

## Exercises

Here is overview of the exercises to be completed during this Hands-on Workshop. Optional add-on exercises are  marked respectively.  
The __Getting Started__ section should be __pursued first__, the other main exercises 1, 2, 3 and 4 can be pursued in order of personal interest.

- [Getting Started - prepare your local VS Code environment](exercises/ex0/)
- [Exercise 1 - Generate time series forecasts on-the-fly using using SAP-RPT-TS from SAP HANA Cloud](exercises/ex1/)
  - [1.1 Explore the Bike Sharing time series data](exercises/ex1#Exercise-1.1-Explore-the-Bike-Sharing-time-series-data)
  - [1.2 Forecast with "SAP-RPT-TS"](exercises/ex1#Exercise-1.2-Forecast-with-"SAP-RPT-TS")
  - [1.3 Forecast multiple time series with "SAP-RPT-TS"](exercises/ex1#Exercise-1.3-Forecast-multiple-time-series-with-"SAP-RPT-TS")
  - [1.4 Utilize "SAP-RPT-TS" with AutoML for time series (optional)](exercises/ex1#Exercise-1.4-Utilize-"SAP-RPT-TS"-with-AutoML-for-time-series-(optional))
  - [1.5 Utilize PAL SQL functions for "SAP-RPT-TS" (optional)](exercises/ex1#Exercise-1.5-Utilize-PAL-SQL-functions-for-"SAP-RPT-TS"-(optional))
- [Exercise 2 - Generate business data predictions using SAP-RPT-1.6 from SAP AI Core](exercises/ex2/)
  - [2.1 Review the remote source for "SAP-RPT-1.6"](exercises/ex2#Exercise-2.1-Review-the-remote-source-for-"SAP-RPT-1.6")
  - [2.2 Explore the GX transaction fraud data](exercises/ex2#Exercise-2.2-Explore-the-GX-transaction-fraud-data)
  - [2.3 Generate predictions with "SAP-RPT-1.6"](exercises/ex2#Exercise-2.3-Generate-predictions-with-"SAP-RPT-1.6")
- [Exercise 3 - Build multi-target neural network prediction models for an order form autocompletion use case](exercises/ex3/)  
  - [3.1 Explore the the sales order data](exercises/e3#Exercise-3.1-Explore-the-sales-order-data)
  - [3.2 Train a multi-target classification model for sales order form autocompletion](exercises/e3#Exercise-3.2-Train-a-"multi-target"-classification-model-for-sales-order-form-autocompletion)
  - [3.3 Predict missing fields, autocomplete new sales orders](exercises/e3#Exercise-3.3-Predict-missing-fields-to-autocomplete-new-sales-orders)
  - [3.4 Measure prediction accuracy](exercises/e3#Exercise-3.4-Measure-prediction-accuracy)
  - [3.5 Improve prediction latency with stateful models (optional)](exercises/e3#Exercise-3.5-Improve-prediction-latency-with-stateful-models-(optional)) <br> <br> 


  OPTIONAL exercise
- [Exercise 4 - Build a service ticket intelligence classification model using AutoML and raw text features](exercises/ex4/)
  - [4.1 Exploring Travel Service Ticket data using SAP HANA Dataframes](exercises/ex4#Exercise-4.1-Exploring-Travel-Service-Ticket-data-using-SAP-HANA-Dataframes) 
  - [4.2 Building a AutoML classification model for Travel Service Tickets](exercises/ex4#Exercise-4.2-Building-a-AutoML-classification-model-for-Travel-Service-Tickets) 
  - [4.3 Evaluate the AutoML model accuracy](exercises/ex4#Exercise-4.3-Evaluate-the-AutoML-model-accuracy) 
  - [4.4 Predicting with the AutoML classification model](exercises/ex4#Exercise-4.4-Predicting-with-the-AutoML-classification-model) 


## Contributing
Please read the [CONTRIBUTING.md](./CONTRIBUTING.md) to understand the contribution guidelines.

## Code of Conduct
Please read the [SAP Open Source Code of Conduct](https://github.com/SAP-samples/.github/blob/main/CODE_OF_CONDUCT.md).

## How to obtain support
Support for the content in this repository is available during the actual time of the online session for which this content has been designed. Otherwise, you may request support via the [Issues](../../issues) tab.

## License
Copyright (c)2026 SAP SE or an SAP affiliate company. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/SAP/<your-project>).
