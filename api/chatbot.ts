
import { ChatRequest } from '../ui/src/app/services/genwealth-api';
import { Database } from './database';

export class Chatbot {
    constructor(private db: Database) { }

    async chat(request: ChatRequest) {
        const query: string = this.getQuery(request);
        
        console.log('request query', query);

        const rows = await this.db.query(query);
        // Chat should return only a single row
        return { llmResponse: rows[0]['llm_response'], llmPrompt: rows[0]['llm_prompt'], query: query };
    }

    private getQuery(request: ChatRequest) {
        const query = `
            ${request.userId ? this.userPreamble(request.userId) : this.preamble} 
                prompt => '${this.safeString(request.prompt)}',
                ${this.getEnrichment(request)}
                ${request.userId ? this.userBio(request.useHistory) : `
                    user_role => 'I am a generic user'`} 
            ); `;

        return query;
    }

    private getEnrichment(request: ChatRequest) {
        let enrichment: string = `
            -- Prompt enrichment
            `;

        if (request.llmRole)
            enrichment += `llm_role => '${this.safeString(request.llmRole)}',
            `;
        if (request.mission)
            enrichment += `mission => '${this.safeString(request.mission)}',
            `;
        if (request.outputInstructions)        
            enrichment += `output_instructions => '${this.safeString(request.outputInstructions)}',
            `;
        if (request.disclaimer)        
            enrichment += `disclaimer => '${this.safeString(request.disclaimer)}',
            `;
        if (request.responseRestrictions)        
            enrichment += `response_restrictions => '${this.safeString(request.responseRestrictions)}',
            `;

        return enrichment;
    }

    private preamble = `            
        SELECT llm_prompt, llm_response 
        FROM llm(
        `;

    private userPreamble(userId: number) {
        return `    
        WITH profile AS (
            SELECT *
            FROM user_profiles 
            WHERE id = ${userId}
        ) 
        SELECT llm_prompt, llm_response, bio 
        FROM profile, llm(
        `;
    }

    private userBio = (useHistory: boolean) => `
        ${useHistory ? 'enable_history => true' : ''}, 
        user_role => CONCAT('My name is ', first_name, ' ', last_name, '. I am ', age, ' years old, and I have a ', risk_profile, ' risk tolerance.'),
        additional_context => CONCAT(E'<BIO>', bio, E'<\BIO>') `;

    private safeString(str: string) {
        return str.replace(/'/g, "''");
    }
}
