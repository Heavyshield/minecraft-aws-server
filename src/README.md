# Python Development Guide

## Setting up Python Virtual Environment

1. Navigate to the `src` directory:
```bash
cd src
```

2. Create a new virtual environment:
```bash
python3 -m venv .venv
```

3. Activate the virtual environment:
- On Windows:
```cmd
.venv\Scripts\activate
```
- On macOS/Linux:
```bash
source .venv/bin/activate
```

4. Install required dependencies:
```bash
pip install -r requirements.txt
```

## Packaging Python Lambda Functions

1. Ensure you are in the virtual environment (see activation steps above)

2. Install your project dependencies (if you want to test lambda locally):
```bash
pip install -r requirements.txt
```

3. Create a deployment package:
```bash
zip lambda_function.zip lambda_function.py
```

4. The resulting `lambda_function.zip` can be used to deploy your Lambda function.

### Best Practices

- Always test your Lambda function locally before deployment
- Keep your dependencies minimal to reduce cold start time
- Include only necessary files in the deployment package
- Use layers for large dependencies that are shared across functions
- Monitor your deployment package size (max 50MB zipped, 250MB unzipped)

### Troubleshooting

- If you see import errors, ensure all dependencies are properly listed in requirements.txt
- For platform-specific packages, use Lambda layers instead of including them in the deployment package
- Clean the package directory before creating new deployment packages to avoid including unnecessary files