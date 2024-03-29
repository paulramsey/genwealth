# GenWealth Demo
This demo showcases how you can combine the data and documents you already have and the skills you already know with the power of AlloyDB AI, Vertex AI, Cloud Run, and Cloud Functions to build trustworthy Gen AI features into your existing applications. 

You will implement an end-to-end “Knowledge Worker Assist” use case for a fictional Financial Services company called GenWealth. GenWealth is an investment advisory firm that combines personalized service with cutting-edge technology to deliver tailored investment strategies to their clients that aim to generate market-beating results.

You we add 3 new Gen AI features to GenWealth’s existing Investment Advisory software:

1. First, you will improve the investment search experience for GenWealth’s Financial Advisors using semantic search powered by AlloyDB AI.
2. Second, you will build a Customer Segmentation feature for GenWealth’s Marketing Analysts to identify prospects for new products and services.
3. Third, you will build a Gen AI chatbot that will supercharge productivity for GenWealth’s Financial Advisors. 

This demo highlights AlloyDB AI’s integration with Vertex AI LLMs for both embeddings and text completion models. You will learn how to query AlloyDB with natural language using embeddings and vector similarity search, and you will build the backend for a RAG-powered Gen AI chatbot that is grounded in your application data.


## Requirements
- Node 20+
- Angular 17+
- AlloyDB for PostgreSQL 14+

## Architecture

### Backend
The backend is hosted in GCP on AlloyDB which makes calls directly to Vertex AI through the database engine. 

### Pipeline
The document extraction pipeline is triggered by uploading a pdf to the `$PROJECT_ID-docs` bucket. The pipeline completes the following steps:

1. The `process-pdf` Cloud Function extracts text from the pdf using Document AI (OCR), chunks the extracted text with LangChain, and writes the chunked text to the `langchain_vector_store` table in AlloyDB.
1. The `analyze-prospectus` Cloud Function retrieves the document chunks from AlloyDB and iteratively builds a company overview, analysis, and buy/sell/hold rating using Vertex AI. Results are saved to the `investments` table in AlloyDB.
1. 


### Middle Tier
The middle tier is written in TypeScript and hosted with `express`: 

```javascript
import express from 'express';
...
const app: express.Application = express();
```

There are a simple set of REST apis hosted at `/api/*` that connect to AlloyDB via the `Database.ts` class.  

```javascript
// Routes for the backend
app.get('/api/investments/search', async (req: express.Request, res: express.Response) => {
  ...
}
```

### Frontend
 
The frontend application is Angular Material using TypeScript, which is built and statically served from the root `/` by express as well:

```javascript
// Serve the frontend
app.use(express.static(staticPath));

```

## Deploying the application

1. Login to the [GCP Console](https://console.cloud.google.com/).

1. [Create a new project](https://developers.google.com/maps/documentation/places/web-service/cloud-setup) to host the demo and isolate it from other resources in your account.

1. [Switch](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects) to your new project.

1. [Activate Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell) and confirm your project by running the following commands. Click **Authorize** if prompted.

    ```bash
    gcloud auth list
    gcloud config list project
    ```

1. Clone this repository and navigate to the project root:
    ```bash
    git clone https://github.com/paulramsey/genwealth.git
    cd genwealth
    ```

1. In a separate tab, navigate to https://ipv4.icanhazip.com/ and write down your device's public IP. You will need this in the next step. 

1. **IMPORTANT:** Use `vim` or `nano` to update the following three values in the `./env.sh` file to match your environment. Leave the rest as default.
    ```bash
    export REGION="us-central1"
    export ZONE="us-central1-a"
    export LOCAL_IPV4="X.X.X.X" # Your device's public IP from the previous step
    ```
1. Run the `./install.sh` script.

1. When prompted, enter a password you will remember for the AlloyDB postgres user and the pgAdmin demo user. **Remember these passwords - you will need them later**.

## Incremental builds

If you prefer to run the deployment one step at a time (perhaps for debugging purposes), run the deployment scripts in the following order:

1. `deploy-backend.sh`
1. `deploy-pipeline.sh`
1. `deploy-search.sh`
1. `deploy-registry.sh`
1. `deploy-frontend.sh`

## Purpose and Extensibility

The purpose of this repo is to help you provision an isolated demo environment that highlights the Generative AI capabilities of AlloyDB AI and Vertex AI. While the ideas in this repo can be extended for many real-world use cases, the demo code itself is overly permissive and has not been hardened for security or reliability. The sample code in this repo is provided on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, and it should NOT be used for production use cases without doing your own testing and security hardening. 


