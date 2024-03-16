import { HttpClient, HttpParams } from '@angular/common/http';
import { Inject, Injectable } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { BASE_URL } from '../app.config';

export interface QueryResponse<T> {
    query?: string;
    data?: T[];
}

export interface Investment {
    ticker?: string;
    etf?: boolean;
    rating?: string;
    analysis?: string;
    distance?: number;
}

export interface Prospect {
    firstName?: string;
    lastName?: string;
    email?: string;
    age?: number,
    risk_profile?: string;
    bio?: string,
    distance?: number;
}

export interface ChatResponse {
    llmPrompt?: string;
    llmResponse?: string;
    query?: string;
}

export class ChatRequest {
    constructor(public prompt: string) {}

    // This flag determines if the other enrichments will be used.
    advanced: boolean = false;
    
    userId?: number;
    useHistory: boolean = false;
    llmRole: string = 'You are an experienced financial advisor named Penny.';
    mission?: string = 'Your mission is to help your clients maximize their return on investment and outperform the general market.'
    outputInstructions?: string = 'Begin your response with a professional greeting. Greet me by name if you know it. End your response with a signature that includes your name and "GenWealth" company affiliation.';
    responseRestrictions: string = 'You have no response restrictions for this prompt.';
    disclaimer?: string;
}

export interface GenWealthService {
    searchInvestments(terms: string[]): Observable<QueryResponse<Investment>>;
    semanticSearchInvestments(prompt: string): Observable<QueryResponse<Investment>>;
    semanticSearchProspects(
        prompt: string,
        riskProfile?: string,
        minAge?: number,
        maxAge?: number): Observable<QueryResponse<Prospect>>;
    chat(request: ChatRequest): Observable<ChatResponse>; 
}

@Injectable({
    providedIn: 'root'
})
export class GenWealthServiceClient implements GenWealthService {
    constructor(private http: HttpClient, @Inject(BASE_URL) private baseUrl: string) {}
    
    searchInvestments(terms: string[]): Observable<QueryResponse<Investment>> {
        if (terms.length === 1) {
            // Caveat - if only a single term is passed, the single term will be split into each char
            // prevent this by adding empty.
            terms = [terms[0], ''];
        }
        return this.http.get<QueryResponse<Investment>>(`${this.baseUrl}/investments/search`, {
            params: { terms: terms }
        });
    }

    semanticSearchInvestments(prompt: string): Observable<QueryResponse<Investment>> {
        return this.http.get<QueryResponse<Investment>>(`${this.baseUrl}/investments/semantic-search`, {
            params: { prompt: prompt }
        });
    }

    semanticSearchProspects(prompt: string, riskProfile?: string | undefined, minAge?: number | undefined, maxAge?: number | undefined): 
            Observable<QueryResponse<Prospect>> {
        let params: HttpParams = new HttpParams().set('prompt', prompt);
        
        if (riskProfile) {
            params = params.set('risk_profile', riskProfile);
        }
        if (minAge) {
            params = params.set('min_age', minAge);
        }
        if (maxAge) {
            params = params.set('max_age', maxAge);
        }

        return this.http.get<QueryResponse<Prospect>>(`${this.baseUrl}/prospects/search`, {params: params});
    }

    chat(request: ChatRequest): Observable<ChatResponse> {
        console.log('chat', request);
        return this.http.post<ChatResponse>(`${this.baseUrl}/chat`, request);
    }
}