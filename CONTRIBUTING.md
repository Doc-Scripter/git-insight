# Contributing to GitInsight

We welcome contributions to GitInsight! By contributing, you help us improve and grow our community. Please take a moment to review this document to ensure a smooth and effective contribution process.

## Table of Contents

- [Contributing to GitInsight](#contributing-to-gitinsight)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [How to Contribute](#how-to-contribute)
    - [Reporting Bugs](#reporting-bugs)
    - [Suggesting Enhancements](#suggesting-enhancements)
    - [Your First Code Contribution](#your-first-code-contribution)
    - [Pull Request Guidelines](#pull-request-guidelines)
  - [Development Setup](#development-setup)
  - [Style Guides](#style-guides)
  - [License](#license)

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on our [GitHub Issues page](https://github.com/your-username/git-insight/issues) and provide the following information:

- A clear and concise description of the bug.
- Steps to reproduce the behavior.
- Expected behavior.
- Actual behavior.
- Screenshots or error messages (if applicable).
- Your operating system and browser details.

### Suggesting Enhancements

If you have an idea for a new feature or an improvement, please open an issue on our [GitHub Issues page](https://github.com/your-username/git-insight/issues) and provide the following information:

- A clear and concise description of the proposed enhancement.
- Why this enhancement would be useful.
- Any alternative solutions you've considered.

### Your First Code Contribution

If you're looking to make your first code contribution, look for issues labeled `good first issue` on our [GitHub Issues page](https://github.com/your-username/git-insight/issues).

### Pull Request Guidelines

Follow these steps to submit a pull request:

1.  **Fork the repository** and clone it to your local machine.
2.  **Create a new branch** from `main` for your feature or bug fix:
    ```bash
    git checkout main
    git pull origin main
    git checkout -b feature/your-feature-name
    # or
    git checkout -b bugfix/your-bug-fix-name
    ```
3.  **Make your changes** and ensure they adhere to the [Style Guides](#style-guides).
4.  **Write tests** for your changes. Ensure all existing tests pass.
5.  **Update documentation** if your changes affect any user-facing features or APIs.
6.  **Commit your changes** with a clear and concise commit message. Follow our [Commit Guidelines](COMMIT_GUIDELINES.md).

7.  **Push your branch** to your forked repository.
8.  **Open a Pull Request** to the `main` branch of the original repository. Fill out the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md) completely.
9.  **Address review comments** promptly.

*   **Code Review:** All contributions require code review.
*   **Cloud Operations:** For details on deployment environments and cloud infrastructure, refer to the [Cloud Operations and Hosting Guide](docs/cloud_operations.md) and the [User Flows Guide](docs/user_flows.md) for understanding user interactions.

## Development Setup

<!-- Provide instructions on how to set up the development environment. This will be specific to the chosen tech stack. Example below: -->

To set up your local development environment, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/git-insight.git
    cd git-insight
    ```
2.  **Install dependencies:**
    *   **Backend (Python/FastAPI):**
        ```bash
        # Assuming you have Python and pip installed
        python -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        ```
    *   **Frontend (SvelteKit/React with Shadcn UI):**
        *   Node.js (LTS version recommended)
        *   npm or Yarn
        ```bash
        npm install # or yarn install
        ```
3.  **Database Setup (PostgreSQL):**
    *   Ensure PostgreSQL is running.
    *   Create a database for the project.
    *   Run migrations (if applicable).

4.  **Run the application:**
    *   **Backend:**
        ```bash
        uvicorn main:app --reload
        ```
    *   **Frontend:**
        ```bash
        npm run dev # or yarn dev
        ```

## Style Guides

<!-- Outline coding style guidelines. Example below: -->

-   **Python:** Adhere to PEP 8.
-   **JavaScript/TypeScript:** Follow Airbnb style guide or similar, enforced by ESLint and Prettier.
-   **Commit Messages:** Adhere to our [Commit Guidelines](COMMIT_GUIDELINES.md).

## License

By contributing to GitInsight, you agree that your contributions will be licensed under the project's [LICENSE](LICENSE) file.