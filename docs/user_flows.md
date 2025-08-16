# GitInsight User Flows

This document outlines the primary user flows within the GitInsight platform, detailing the steps users take to achieve their goals, the system's responses, and key decision points.

## 1. Onboarding and Initial Repository Setup

**User Action:** User lands on the GitInsight platform.
**System Response:** Displays a welcoming page with an overview of the platform's capabilities, including sections like "Find alternatives to major proprietary software" (showing their cards), "Utility Repos," and "Gaming Repos."

**User Action:** User searches for a GitHub repository or alternatives, including proprietary software (e.g., "Adobe").
**System Response:** Displays search results with basic information about repositories or alternative open-source software. (No sign-up/sign-in required)

**User Action:** User compares repositories or gets detailed information on them.
**System Response:** Prompts user to sign in/sign up if not already authenticated, then displays comparison or detailed information. (Sign-in/Sign-up required)

**User Action:** User selects a repository for analysis.
**System Response:** Initiates the analysis process and displays a loading indicator.

**User Action:** User views the analysis results.
**System Response:** Presents a dashboard with key insights, metrics, and visualizations.

**User Action:** User adds and follows repositories to get recent issue updates and changes.
**System Response:** Prompts user to subscribe if not already subscribed, then adds the repository to their followed list and provides updates. (Subscription required)

## 2. Repository Analysis and Insight Viewing

**Goal:** A user explores detailed insights for a specific GitHub repository.

1.  **User Action:** Logs in or navigates to the dashboard.
    *   **System Response:** Displays the main dashboard with a summary of analyzed repositories and high-level metrics.
2.  **User Action:** Selects a specific repository from the list or search results.
    *   **System Response:** Navigates to the detailed insights page for that repository.
3.  **User Action:** Views various insight categories (e.g., "Code Quality", "Contributor Activity", "Dependency Analysis", "License Information", "AI-driven Summaries").
    *   **System Response:** Displays interactive charts, graphs, and textual summaries relevant to the selected category.
4.  **User Action:** Filters or sorts insights (e.g., by date range, contributor, file type).
    *   **System Response:** Updates the displayed insights based on the applied filters.
5.  **User Action:** Clicks on specific data points or elements within the insights (e.g., a contributor's name, a file path).
    *   **System Response:** Provides drill-down details or related information (e.g., contributor's activity timeline, code snippets).

## 3. Search and Discovery of New Repositories

**Goal:** A user finds and adds new public GitHub repositories for analysis.

1.  **User Action:** Navigates to the "Discover" or "Add Repository" section.
    *   **System Response:** Displays a search interface for GitHub repositories.
2.  **User Action:** Enters search queries (e.g., repository name, topic, language).
    *   **System Response:** Displays a list of matching public GitHub repositories.
3.  **User Action:** Applies filters to search results (e.g., "stars", "forks", "last updated", "license type").
    *   **System Response:** Refines the search results based on filters.
4.  **User Action:** Selects a repository from the search results.
    *   **System Response:** Displays a preview of the repository's basic information and an "Add to Analysis" button.
5.  **User Action:** Clicks "Add to Analysis".
    *   **System Response:** Initiates the data ingestion and analysis for the new repository. Adds it to the user's list of analyzed repositories and provides a progress notification.

## 4. Customization and Reporting

**Goal:** A user customizes their view of insights and generates reports.

1.  **User Action:** Navigates to the dashboard or a specific repository's insight page.
    *   **System Response:** Displays the current view of insights.
2.  **User Action:** Accesses customization options (e.g., "Customize Dashboard", "Report Settings").
    *   **System Response:** Presents options to reorder widgets, select metrics, or configure report parameters.
3.  **User Action:** Configures report parameters (e.g., date range, specific insights to include, format).
    *   **System Response:** Previews the report or confirms settings.
4.  **User Action:** Clicks "Generate Report" or "Download Report".
    *   **System Response:** Generates the report in the specified format (e.g., PDF, CSV) and initiates download or sends it to the user's email.
5.  **User Action:** Sets up notifications or alerts for specific events (e.g., new critical vulnerability detected, significant change in code quality).
    *   **System Response:** Confirms notification settings and provides options for delivery channels (e.g., email, in-app).

## 5. Account Management

**Goal:** A user manages their profile, connected accounts, and subscription.

1.  **User Action:** Navigates to "Settings" or "Profile" section.
    *   **System Response:** Displays account information and various management tabs.
2.  **User Action:** Updates profile details (e.g., name, email, password).
    *   **System Response:** Saves changes and provides confirmation.
3.  **User Action:** Manages connected GitHub accounts (e.g., disconnects an account, adds another).
    *   **System Response:** Displays connected accounts and options to add/remove.
4.  **User Action:** Views subscription details or billing history.
    *   **System Response:** Displays current plan, usage, and past invoices.
5.  **User Action:** (Optional) Upgrades or downgrades subscription plan.
    *   **System Response:** Guides through the plan selection and payment process.