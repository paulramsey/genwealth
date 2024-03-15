
import { Database } from './database';

export class Investments {
    constructor(private db: Database) { }

    async search(searchTerms: string[]) {
        console.log('using searchTerms', searchTerms);
        let query = `SELECT ticker, etf, rating, analysis
            FROM investments
            WHERE analysis LIKE '%${searchTerms[0] ?? ''}%'`;
        
        for (let i = 1; i < searchTerms.length; i++) {
            if (searchTerms[i].trim() !== '') {
                query += `
                    AND analysis LIKE '%${searchTerms[i].trim()}%'`;
            }
        }
        
        query += `LIMIT 5;`

        const rows = await this.db.query(query);
        return { data: rows, query: query };
    }

    async semanticSearch(prompt: string) {
        const query = `SELECT ticker, etf, rating, analysis, 
            analysis_embedding <=> embedding('textembedding-gecko@003', '${prompt}') AS distance
            FROM investments
            ORDER BY distance
            LIMIT 5;`;

        const rows = await this.db.query(query);
        return { data: rows, query: query };
    }
}
